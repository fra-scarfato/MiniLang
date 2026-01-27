open MiniRISCCFG
open MiniRISCUtils

(* ========== Data-Flow Analysis Modules ========== *)

(* Get all registers used in the CFG *)
let get_all_registers cfg =
  BlockMap.fold
    (fun _ block acc ->
      List.fold_left
        (fun acc cmd ->
          let used = get_used_registers cmd in
          let defined = get_defined_registers cmd in
          List.fold_right RegisterSet.add (used @ defined) acc
        )
        acc block.commands
    )
    cfg.blocks RegisterSet.empty

(* ========== Definite Variables Analysis (Forward / Must) ========== *)
(* Computed Value: Set of definitely defined variables (registers)
   Analysis State: Associate IN and OUT values to each block
   - IN[B]: variables defined at block entry
   - OUT[B]: variables defined at block exit
   Local Update: OUT[B] = IN[B] ∪ Defined[B]
   Global Update: IN[B] = ∩ OUT[P] for all predecessors P *)
module DefiniteVariables = struct
  (* Analysis State: maps block_id -> (IN, OUT) sets *)
  type analysis_result = {
    in_sets : RegisterSet.t BlockMap.t;
    out_sets : RegisterSet.t BlockMap.t;
  }

  (* Compute variables defined by this block *)
  let compute_defined (block : risc_cfg_block) : RegisterSet.t =
    (* Accumulate the register defined in the block *)
    List.fold_left
      (fun acc cmd ->
        let defs = get_defined_registers cmd in
        (* Add all defined registers from this command to the accumulator *)
        List.fold_right RegisterSet.add defs acc
      )
      RegisterSet.empty block.commands

  let analyze ?(verbose = false) (cfg : risc_cfg) : analysis_result =
    log_verbose verbose "\n=== Definite Variables Analysis ===";
    let all_regs = get_all_registers cfg in
    log_verbose verbose "All registers in CFG: %s" (string_of_regset all_regs);

    (* Initialize: Eache entry starts from TOP (all registers) This is a MUST
       analysis, so we use greatest fixpoint starting from TOP *)
    let init_state = BlockMap.mapi (fun _ _ -> all_regs) cfg.blocks in

    if verbose then (
      print_endline "\nInitial state:";
      BlockMap.iter
        (fun id set ->
          Printf.printf "  Block %d OUT: %s\n" id (string_of_regset set)
        )
        init_state
    );

    (* For each block, it computes registers defined at entr and exit. They are
       saved in the state: block_id -> {r_0, r_1, ...} *)
    let rec iterate iteration out_state =
      log_verbose verbose "\n--- Iteration %d (Global Update) ---" iteration;

      let new_out_state, new_in_state, changed =
        BlockMap.fold
          (fun id block (acc_out_state, acc_in_state, acc_changed) ->
            (* Get predecessors of the current block *)
            let preds = get_predecessors cfg id in

            (* Compute IN values for the current block *)
            let in_value =
              match preds with
              | [] ->
                  (* No predecessors *)
                  (* Entry block starts with input_register defined *)
                  if id = cfg.entry then RegisterSet.singleton input_register
                  (* Unreachable block (no predecessors) starts with TOP *)
                    else all_regs
              | p :: ps ->
                  (* One or more predecessors *)
                  (* Get the OUT set of the predecessor *)
                  let get_out p =
                    try BlockMap.find p out_state with Not_found -> all_regs
                  in
                  (* Intersect the OUT sets of all predecessors *)
                  List.fold_left
                    (fun acc p -> RegisterSet.inter acc (get_out p))
                    (get_out p) ps
            in

            (* Local Update: variables at exit = variables at entry + variables
               defined by block *)
            (* Compute registers defined by this block *)
            let defined_here = compute_defined block in
            (* Compute OUT values for the current block: OUT[B] = IN[B] ∪
               Defined[B] *)
            let out_value = RegisterSet.union in_value defined_here in

            (* Track changes *)
            let old_out = BlockMap.find id out_state in
            let has_changed = not (RegisterSet.equal out_value old_out) in

            log_verbose verbose "Block %d: IN=%s DEFINED=%s OUT=%s %s" id
              (string_of_regset in_value)
              (string_of_regset defined_here)
              (string_of_regset out_value)
              (if has_changed then "[CHANGED]" else "");

            (* Update IN and OUT and track if any changes occurred *)
            ( BlockMap.add id out_value acc_out_state,
              BlockMap.add id in_value acc_in_state,
              acc_changed || has_changed
            )
          )
          cfg.blocks
          (out_state, BlockMap.empty, false)
      in

      (* If any changes occurred, continue iterating *)
      if changed then iterate (iteration + 1) new_out_state
      (* Else, fixpoint reached *)
        else (iteration, new_out_state, new_in_state)
    in

    (* Start the iteration process with the initial state *)
    let final_iteration, final_out, final_in = iterate 1 init_state in
    if verbose then (
      log_verbose verbose "\nFixpoint reached after %d iterations"
        final_iteration;
      BlockMap.iter
        (fun id set ->
          Printf.printf "  Block %d OUT: %s\n" id (string_of_regset set)
        )
        final_out
    );
    { in_sets = final_in; out_sets = final_out }

  let check_safety ?(verbose = false) (cfg : risc_cfg) : bool =
    log_verbose verbose "\n=== SAFETY CHECK ===";

    (* Perform dataflow analysis to get defined registers at entry and exit of
       each block *)
    let analysis_result = analyze ~verbose cfg in

    (* For each block, check that all used registers are defined before use *)
    let check_block id block =
      log_verbose verbose "\nChecking Block %d:" id;

      (* Get the IN values from analysis for the current block *)
      let initial_defs =
        try BlockMap.find id analysis_result.in_sets
        with Not_found -> RegisterSet.singleton input_register
      in

      log_verbose verbose "  Initial defs: %s" (string_of_regset initial_defs);

      let check_cmd (current_defs, errors) cmd =
        (* Get used registers in this command *)
        let used = get_used_registers cmd in
        (* Get registers defined by this command *)
        let defs = get_defined_registers cmd in

        if verbose then (
          log_verbose verbose "  Cmd: %s" (string_of_command cmd);
          log_verbose verbose "    Uses: %s"
            (String.concat ", " (List.map string_of_register used));
          log_verbose verbose "    Defs: %s"
            (String.concat ", " (List.map string_of_register defs))
        );

        let new_errors =
          List.fold_left
            (fun errs r ->
              (* Check if the register 'r' is defined before use *)
              if not (RegisterSet.mem r current_defs) then begin
                let err =
                  Printf.sprintf "Block %d: Register %s used before definition"
                    id (string_of_register r)
                in
                log_verbose verbose "    ERROR: %s" err;
                err :: errs
              end
              else begin
                log_verbose verbose "    %s is defined" (string_of_register r);
                errs
              end
            )
            errors used
        in

        (* Update the set of defined registers after this command *)
        let updated_defs = List.fold_right RegisterSet.add defs current_defs in
        log_verbose verbose "    After: defs = %s"
          (string_of_regset updated_defs);
        (updated_defs, new_errors)
      in

      (* Check each command in the block *)
      let defs_after_cmds, errors_after_cmds =
        List.fold_left check_cmd (initial_defs, []) block.commands
      in

      (* Check the terminator in the block *)
      let final_errors =
        match block.terminator with
        | Some term ->
            log_verbose verbose "  Terminator:";
            let _, errs = check_cmd (defs_after_cmds, errors_after_cmds) term in
            errs
        | None -> errors_after_cmds
      in
      final_errors
    in

    (* Check each block in the CFG and collect errors *)
    let all_errors =
      BlockMap.fold
        (fun id block acc ->
          let block_errors = check_block id block in
          block_errors @ acc
        )
        cfg.blocks []
    in

    log_verbose verbose "\n=== SAFETY CHECK RESULT ===";
    match all_errors with
    | [] ->
        log_verbose verbose
          "Safety Check Passed - No uninitialized variables found.";
        if not verbose then print_endline "Safety check passed";
        true
    | errs ->
        print_endline "Safety check FAILED - Uninitialized variables found:";
        List.iter (fun err -> Printf.printf "  %s\n" err) (List.rev errs);
        false
end

(* ========== Live Variables Analysis (Backward / May) ========== *)
(* Computed Value: Set of live variables (registers that may be used later)
   Analysis State: Associate IN and OUT values to each block
   - IN[B]: variables live at block entry
   - OUT[B]: variables live at block exit
   Local Update: IN[B] = UpwardExposed[B] ∪ (OUT[B] - Killed[B])
   Global Update: OUT[B] = ∪ IN[S] for all successors S *)
module LiveVariables = struct
  type analysis_result = RegisterSet.t BlockMap.t

  (* Compute upward exposed uses and variables killed by this block *)
  let compute_local_info (block : risc_cfg_block) =
    let upward_exposed, killed =
      List.fold_left
        (fun (exposed, killed) cmd ->
          let uses = get_used_registers cmd in
          let defs = get_defined_registers cmd in

          (* A use is upward exposed if it's used before being defined *)
          let new_exposed =
            List.fold_left
              (fun acc u ->
                if RegisterSet.mem u killed then acc else RegisterSet.add u acc
              )
              exposed uses
          in
          let new_killed = List.fold_right RegisterSet.add defs killed in
          (new_exposed, new_killed)
        )
        (RegisterSet.empty, RegisterSet.empty)
        block.commands
    in

    (* Handle terminator *)
    match block.terminator with
    | None -> (upward_exposed, killed)
    | Some term ->
        let uses = get_used_registers term in
        let final_exposed =
          List.fold_left
            (fun acc u ->
              if RegisterSet.mem u killed then acc else RegisterSet.add u acc
            )
            upward_exposed uses
        in
        (final_exposed, killed)

  let analyze ?(verbose = false) (cfg : risc_cfg) : analysis_result =
    log_verbose verbose "\n=== LIVE VARIABLES ANALYSIS ===";

    (* Initialize: all blocks have empty IN *)
    let init_state = BlockMap.map (fun _ -> RegisterSet.empty) cfg.blocks in

    let rec iterate iteration state =
      log_verbose verbose "\n--- Iteration %d ---" iteration;

      let new_state, changed =
        BlockMap.fold
          (fun id block (acc_state, acc_changed) ->
            let succs = get_successors cfg id in

            (* OUT[B] = ∪ IN[S] for all successors S *)
            let out_value =
              if id = cfg.exit then RegisterSet.singleton output_register
              else
                List.fold_left
                  (fun acc (succ_id, _) ->
                    let succ_in =
                      try BlockMap.find succ_id state
                      with Not_found -> RegisterSet.empty
                    in
                    RegisterSet.union acc succ_in
                  )
                  RegisterSet.empty succs
            in

            (* IN[B] = UpwardExposed[B] ∪ (OUT[B] - Killed[B]) *)
            let upward_exposed, killed = compute_local_info block in
            let in_value =
              RegisterSet.union upward_exposed
                (RegisterSet.diff out_value killed)
            in

            let old_in = BlockMap.find id state in
            let has_changed = not (RegisterSet.equal in_value old_in) in

            log_verbose verbose
              "Block %d: UPWARD_EXPOSED=%s KILLED=%s OUT=%s IN=%s %s" id
              (string_of_regset upward_exposed)
              (string_of_regset killed)
              (string_of_regset out_value)
              (string_of_regset in_value)
              (if has_changed then "[CHANGED]" else "");

            (BlockMap.add id in_value acc_state, acc_changed || has_changed)
          )
          cfg.blocks (state, false)
      in

      if changed then iterate (iteration + 1) new_state
      else (iteration, new_state)
    in

    let final_iteration, result = iterate 1 init_state in
    if verbose then (
      log_verbose verbose "\nFixpoint reached after %d iterations"
        final_iteration;
      BlockMap.iter
        (fun id set ->
          Printf.printf "  Block %d IN: %s\n" id (string_of_regset set)
        )
        result
    );
    result
end

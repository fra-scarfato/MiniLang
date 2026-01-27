open MiniRISCSyntax
open MiniRISCCFG
open MiniRISCUtils

(* ========== Data-Flow Analysis Modules ========== *)

(* Logging utility *)
let log_verbose verbose fmt =
  Printf.ksprintf (fun s -> if verbose then print_endline s else ()) fmt

(* Module for Register Sets *)
module RegisterSet = Set.Make (struct
  type t = register
  let compare = compare
end)

(* Module for Register Maps *)
module RegisterMap = Map.Make (struct
  type t = register
  let compare = compare
end)

(* Helper to print register sets *)
let string_of_regset set =
  let regs = RegisterSet.elements set in
  "{" ^ String.concat ", " (List.map string_of_register regs) ^ "}"

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
    log_verbose verbose "\n=== DEFINITE VARIABLES ANALYSIS ===";
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

    (* For each block, it computes registers defined at entr and exit. 
       They are saved in the state: block_id -> {r_0, r_1, ...} *)
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
            (* Compute OUT values for the current block:
               OUT[B] = IN[B] ∪ Defined[B] *)
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
            (BlockMap.add id out_value acc_out_state,
             BlockMap.add id in_value acc_in_state,
             acc_changed || has_changed)
          )
          cfg.blocks (out_state, BlockMap.empty, false)
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

    (* Perform dataflow analysis to get defined registers at entry and exit of each block *)
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
                if RegisterSet.mem u killed then acc else RegisterSet.add u acc)
              exposed uses
          in
          let new_killed = List.fold_right RegisterSet.add defs killed in
          (new_exposed, new_killed))
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
              if RegisterSet.mem u killed then acc else RegisterSet.add u acc)
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
                    RegisterSet.union acc succ_in)
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

            (BlockMap.add id in_value acc_state, acc_changed || has_changed))
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
          Printf.printf "  Block %d IN: %s\n" id (string_of_regset set))
        result);
    result
end

(* ========== Register Allocation with Memory Spilling ========== *)
module RegisterAllocation = struct
  type location = InRegister of register | InMemory of int

  (* Physical register layout for n total registers:
     - r_in  (input)
     - r_out (output)  
     - r0, r1, ..., r(n-5) (n-4 general purpose registers)
     - r(n-2) = r_a (swap register A)
     - r(n-1) = r_b (swap register B)
  *)
  
  let r_in_reg = Register "r_in"
  let r_out_reg = Register "r_out"

  (* Get the two swap registers based on target count *)
  let get_swap_registers n_target =
    let r_a = Register ("r" ^ string_of_int (n_target - 2)) in
    let r_b = Register ("r" ^ string_of_int (n_target - 1)) in
    (r_a, r_b)

  (* --- Allocation Strategy --- *)
  
  (* Compute usage frequency for each register *)
  let get_frequencies cfg =
    let incr map r =
      let c = try RegisterMap.find r map with Not_found -> 0 in
      RegisterMap.add r (c + 1) map
    in
    BlockMap.fold
      (fun _ block acc ->
        let cmds = block.commands @ Option.to_list block.terminator in
        List.fold_left
          (fun acc cmd ->
            List.fold_left incr acc
              (get_used_registers cmd @ get_defined_registers cmd))
          acc cmds)
      cfg.blocks RegisterMap.empty

  (* Allocate registers to physical locations
     Strategy:
     - r_in and r_out always get physical registers (don't count against limit)
     - Top (n-4) most frequently used variables get physical registers
     - Remaining variables spilled to memory
  *)
  let allocate_locations ?(verbose = false) cfg n_target =
    log_verbose verbose "\n=== REGISTER ALLOCATION ===";
    log_verbose verbose "Target: %d registers" n_target;
    log_verbose verbose "Layout: r_in, r_out, r0..r%d, r%d(r_a), r%d(r_b)"
      (n_target - 5) (n_target - 2) (n_target - 1);

    let freqs = get_frequencies cfg in
    
    log_verbose verbose "\n--- Frequency Analysis ---";
    let sorted =
      RegisterMap.bindings freqs
      |> List.sort (fun (_, c1) (_, c2) -> compare c2 c1)
    in
    if verbose then
      List.iter (fun (Register name, count) ->
        Printf.printf "  %s: %d uses\n" name count
      ) sorted;
    
    let sorted_regs = List.map fst sorted in
    
    (* Available slots: n total - 2 for in/out - 2 for r_a/r_b = n-4 *)
    let available_slots = max 0 (n_target - 4) in
    log_verbose verbose "\nAvailable slots for general registers: %d" available_slots;

    log_verbose verbose "\n--- Allocation Decisions ---";
    
    (* Allocate: r_in and r_out get registers, then top (n-4) by frequency *)
    let alloc_map, next_mem_addr, _ =
      List.fold_left
        (fun (map, next_addr, slots_used) reg ->
          if reg = r_in_reg || reg = r_out_reg then
            (* Always allocate r_in/r_out to registers *)
            let () = log_verbose verbose "  %s -> %s (special register)"
              (string_of_register reg) (string_of_register reg) in
            (RegisterMap.add reg (InRegister reg) map, next_addr, slots_used)
          else if slots_used < available_slots then
            (* Allocate to physical register *)
            let () = log_verbose verbose "  %s -> Physical register (slot %d/%d)"
              (string_of_register reg) (slots_used + 1) available_slots in
            (RegisterMap.add reg (InRegister reg) map, next_addr, slots_used + 1)
          else
            (* Spill to memory *)
            let () = log_verbose verbose "  %s -> Memory[%d] (spilled)"
              (string_of_register reg) next_addr in
            (RegisterMap.add reg (InMemory next_addr) map, next_addr + 1,
             slots_used))
        (RegisterMap.empty, 0, 0) sorted_regs
    in
    
    log_verbose verbose "\nTotal memory addresses used: %d" next_mem_addr;
    alloc_map

  (* --- Code Rewriting with Spilling --- *)

  (* Load a register from memory if needed, using a temp register *)
  let load_if_needed map reg temp_reg =
    match RegisterMap.find_opt reg map with
    | Some (InRegister r) -> ([], r)
    | Some (InMemory addr) ->
        ([LoadI (addr, temp_reg); Load (temp_reg, temp_reg)], temp_reg)
    | None -> ([], reg)

  (* Store a register to memory if needed and if it's live *)
  let store_if_needed map reg val_reg addr_temp_reg is_live =
    match RegisterMap.find_opt reg map with
    | Some (InMemory addr) when is_live ->
        [LoadI (addr, addr_temp_reg); Store (val_reg, addr_temp_reg)]
    | _ -> []

  (* Rewrite a block with load/store instructions for spilled registers *)
  let rewrite_block ?(verbose = false) r_a r_b alloc_map block live_out_set =
    log_verbose verbose "\n--- Rewriting Block %d ---" block.id;
    log_verbose verbose "Live-out: %s" (string_of_regset live_out_set);
    
    (* Process commands backwards to track liveness for dead store elimination *)
    let process_cmd cmd (acc_cmds, live_after, stores_eliminated) =
      (* Rewrite the command with loads/stores *)
      let rewritten_cmds, store_eliminated =
        match cmd with
        | BinRegOp (op, r1, r2, rd) ->
            let l1, t1 = load_if_needed alloc_map r1 r_a in
            let l2, t2 = load_if_needed alloc_map r2 r_b in

            let dest_is_mem =
              match RegisterMap.find_opt rd alloc_map with
              | Some (InMemory _) -> true
              | _ -> false
            in
            let op_dest = if dest_is_mem then t1 else rd in
            
            let is_live = RegisterSet.mem rd live_after in
            let stores = store_if_needed alloc_map rd op_dest r_b is_live in
            
            let eliminated = dest_is_mem && not is_live in
            if verbose && eliminated then
              Printf.printf "  Dead store eliminated for %s\n" (string_of_register rd);
            
            (l1 @ l2 @ [BinRegOp (op, t1, t2, op_dest)] @ stores, eliminated)
            
        | UnaryOp (op, r1, rd) ->
            let l1, t1 = load_if_needed alloc_map r1 r_a in
            let dest_is_mem =
              match RegisterMap.find_opt rd alloc_map with
              | Some (InMemory _) -> true
              | _ -> false
            in
            let op_dest = if dest_is_mem then t1 else rd in
            
            let is_live = RegisterSet.mem rd live_after in
            let stores = store_if_needed alloc_map rd op_dest r_b is_live in
            
            let eliminated = dest_is_mem && not is_live in
            if verbose && eliminated then
              Printf.printf "  Dead store eliminated for %s\n" (string_of_register rd);
            
            (l1 @ [UnaryOp (op, t1, op_dest)] @ stores, eliminated)
            
        | BinImmOp (op, r1, imm, rd) ->
            let l1, t1 = load_if_needed alloc_map r1 r_a in
            let dest_is_mem =
              match RegisterMap.find_opt rd alloc_map with
              | Some (InMemory _) -> true
              | _ -> false
            in
            let op_dest = if dest_is_mem then t1 else rd in
            
            let is_live = RegisterSet.mem rd live_after in
            let stores = store_if_needed alloc_map rd op_dest r_b is_live in
            
            let eliminated = dest_is_mem && not is_live in
            if verbose && eliminated then
              Printf.printf "  Dead store eliminated for %s\n" (string_of_register rd);
            
            (l1 @ [BinImmOp (op, t1, imm, op_dest)] @ stores, eliminated)
            
        | LoadI (imm, rd) ->
            let dest_is_mem =
              match RegisterMap.find_opt rd alloc_map with
              | Some (InMemory _) -> true
              | _ -> false
            in
            let op_dest = if dest_is_mem then r_a else rd in
            
            let is_live = RegisterSet.mem rd live_after in
            let stores = store_if_needed alloc_map rd op_dest r_b is_live in
            
            let eliminated = dest_is_mem && not is_live in
            if verbose && eliminated then
              Printf.printf "  Dead store eliminated for %s\n" (string_of_register rd);
            
            ([LoadI (imm, op_dest)] @ stores, eliminated)
            
        | Load (addr, rd) ->
            let la, ta = load_if_needed alloc_map addr r_a in
            let dest_is_mem =
              match RegisterMap.find_opt rd alloc_map with
              | Some (InMemory _) -> true
              | _ -> false
            in
            let op_dest = if dest_is_mem then r_b else rd in
            
            let is_live = RegisterSet.mem rd live_after in
            let stores = store_if_needed alloc_map rd op_dest r_a is_live in
            
            let eliminated = dest_is_mem && not is_live in
            if verbose && eliminated then
              Printf.printf "  Dead store eliminated for %s\n" (string_of_register rd);
            
            (la @ [Load (ta, op_dest)] @ stores, eliminated)
            
        | Store (src, addr) ->
            let ls, ts = load_if_needed alloc_map src r_a in
            let la, ta = load_if_needed alloc_map addr r_b in
            (ls @ la @ [Store (ts, ta)], false)
            
        | _ -> ([cmd], false)
      in

      (* Update liveness backwards: In = (Out - Def) ∪ Use *)
      let uses = get_used_registers cmd in
      let defs = get_defined_registers cmd in
      let live_before =
        let after_kill = RegisterSet.diff live_after (RegisterSet.of_list defs) in
        RegisterSet.union after_kill (RegisterSet.of_list uses)
      in
      
      (rewritten_cmds @ acc_cmds, live_before, 
       stores_eliminated + (if store_eliminated then 1 else 0))
    in

    (* Process commands backwards *)
    let final_cmds, _, total_eliminated =
      List.fold_right process_cmd block.commands ([], live_out_set, 0)
    in

    log_verbose verbose "Dead stores eliminated: %d" total_eliminated;

    (* Handle terminator *)
    let term_cmds, new_term =
      match block.terminator with
      | Some (CJump (cond, l1, l2)) ->
          let l, t = load_if_needed alloc_map cond r_a in
          (l, Some (CJump (t, l1, l2)))
      | t -> ([], t)
    in

    { block with
      commands = final_cmds @ term_cmds;
      terminator = new_term
    }

  (* --- Register Renaming --- *)

  (* Collect all unique registers in the CFG *)
  let collect_registers cfg =
    BlockMap.fold
      (fun _ block acc ->
        let cmds = block.commands @ Option.to_list block.terminator in
        List.fold_left
          (fun acc cmd ->
            let used = get_used_registers cmd in
            let defined = get_defined_registers cmd in
            List.fold_right RegisterSet.add (used @ defined) acc)
          acc cmds)
      cfg.blocks RegisterSet.empty

  (* Sort registers with priority ordering *)
  let sort_registers n_target registers =
    let r_a, r_b = get_swap_registers n_target in

    let input_reg, rest1 = List.partition (( = ) r_in_reg) registers in
    let output_reg, rest2 = List.partition (( = ) r_out_reg) rest1 in
    let swap_regs, others =
      List.partition (fun r -> r = r_a || r = r_b) rest2
    in

    (* Order: r_in, r_out, others, swaps *)
    input_reg @ output_reg @ others @ swap_regs

  (* Create renaming map: virtual → physical *)
  let create_renaming_map ?(verbose = false) cfg n_target =
    log_verbose verbose "\n=== REGISTER RENAMING ===";
    
    let registers = RegisterSet.elements (collect_registers cfg) in
    let sorted = sort_registers n_target registers in
    let r_a, r_b = get_swap_registers n_target in

    log_verbose verbose "Total unique registers: %d" (List.length registers);
    log_verbose verbose "\n--- Renaming Map ---";

    let _, map =
      List.fold_left
        (fun (idx, map) reg ->
          (* Special handling for in/out/swap registers *)
          if reg = r_in_reg then
            let () = log_verbose verbose "  %s -> r_in" (string_of_register reg) in
            (idx, RegisterMap.add reg r_in_reg map)
          else if reg = r_out_reg then
            let () = log_verbose verbose "  %s -> r_out" (string_of_register reg) in
            (idx, RegisterMap.add reg r_out_reg map)
          else if reg = r_a then
            let new_name = "r" ^ string_of_int (n_target - 4) in
            let () = log_verbose verbose "  %s -> %s (r_a)" (string_of_register reg) new_name in
            (idx, RegisterMap.add reg (Register new_name) map)
          else if reg = r_b then
            let new_name = "r" ^ string_of_int (n_target - 3) in
            let () = log_verbose verbose "  %s -> %s (r_b)" (string_of_register reg) new_name in
            (idx, RegisterMap.add reg (Register new_name) map)
          else
            (* General purpose registers: r0, r1, ..., r(n-5) *)
            let new_name = "r" ^ string_of_int idx in
            let () = log_verbose verbose "  %s -> %s" (string_of_register reg) new_name in
            (idx + 1, RegisterMap.add reg (Register new_name) map))
        (0, RegisterMap.empty) sorted
    in
    map

  (* Rename a single register *)
  let rename_register map reg =
    try RegisterMap.find reg map with Not_found -> reg

  (* Rename registers in a command *)
  let rename_command map = function
    | Nop -> Nop
    | BinRegOp (op, r1, r2, rd) ->
        BinRegOp
          (op, rename_register map r1, rename_register map r2,
           rename_register map rd)
    | BinImmOp (op, r1, imm, rd) ->
        BinImmOp (op, rename_register map r1, imm, rename_register map rd)
    | UnaryOp (op, r1, rd) ->
        UnaryOp (op, rename_register map r1, rename_register map rd)
    | Load (r1, r2) ->
        Load (rename_register map r1, rename_register map r2)
    | LoadI (imm, r) -> LoadI (imm, rename_register map r)
    | Store (r1, r2) ->
        Store (rename_register map r1, rename_register map r2)
    | Jump l -> Jump l
    | CJump (r, l1, l2) -> CJump (rename_register map r, l1, l2)

  (* Apply renaming to entire CFG *)
  let rename_cfg ?(verbose = false) n_target cfg =
    let map = create_renaming_map ~verbose cfg n_target in
    let new_blocks =
      BlockMap.map
        (fun block ->
          let new_commands = List.map (rename_command map) block.commands in
          let new_terminator = Option.map (rename_command map) block.terminator in
          { block with commands = new_commands; terminator = new_terminator })
        cfg.blocks
    in
    { cfg with blocks = new_blocks }

  (* --- Main Entry Points --- *)

  (* Register allocation with liveness analysis (optimized) *)
  let reduce_registers ?(verbose = false) n cfg =
    if n < 4 then failwith "Target registers must be >= 4 (need r_in, r_out, r_a, r_b)";
    
    log_verbose verbose "\n========================================";
    log_verbose verbose "REGISTER REDUCTION: %d target registers" n;
    log_verbose verbose "========================================";
    
    let r_a, r_b = get_swap_registers n in
    let alloc_map = allocate_locations ~verbose cfg n in
    let liveness = LiveVariables.analyze ~verbose cfg in

    log_verbose verbose "\n=== CODE REWRITING ===";
    let new_blocks =
      BlockMap.mapi
        (fun id block ->
          (* Compute live-out for this block *)
          let live_out_at_end =
            let succs = get_successors cfg id in
            if id = cfg.exit then RegisterSet.singleton r_out_reg
            else
              List.fold_left
                (fun acc (sid, _) ->
                  RegisterSet.union acc
                    (try BlockMap.find sid liveness
                     with Not_found -> RegisterSet.empty))
                RegisterSet.empty succs
          in
          rewrite_block ~verbose r_a r_b alloc_map block live_out_at_end)
        cfg.blocks
    in
    
    (* Apply renaming to get final physical register names *)
    let final_cfg = rename_cfg ~verbose n { cfg with blocks = new_blocks } in
    
    log_verbose verbose "\n=== REGISTER REDUCTION COMPLETE ===\n";
    final_cfg

  (* Register allocation without liveness (conservative, always stores) *)
  let reduce_registers_simple ?(verbose = false) n cfg =
    if n < 4 then failwith "Target registers must be >= 4";
    
    log_verbose verbose "\n========================================";
    log_verbose verbose "REGISTER REDUCTION (SIMPLE): %d target registers" n;
    log_verbose verbose "========================================";
    
    let r_a, r_b = get_swap_registers n in
    let alloc_map = allocate_locations ~verbose cfg n in
    
    (* Conservative: assume all registers are always live *)
    let all_live = get_all_registers cfg in
    
    log_verbose verbose "\n=== CODE REWRITING (No liveness analysis) ===";
    let new_blocks =
      BlockMap.mapi
        (fun _ block -> rewrite_block ~verbose r_a r_b alloc_map block all_live)
        cfg.blocks
    in
    
    (* Apply renaming to get final physical register names *)
    let final_cfg = rename_cfg ~verbose n { cfg with blocks = new_blocks } in
    
    log_verbose verbose "\n=== REGISTER REDUCTION COMPLETE ===\n";
    final_cfg
end
open MiniRISCCFG
open MiniRISCUtils

(* =============================================================================
 * DATAFLOW ANALYSIS: Understanding program behavior without executing it
 * =============================================================================
 *
 * Dataflow analysis is how compilers figure out properties of a program by
 * analyzing the control flow graph.
 *
 * We implement TWO analyses here:
 *
 * 1. DEFINITE VARIABLES (Forward, Must Analysis)
 *    Question: "Which variables are DEFINITELY defined before this point?"
 *    Use case: Safety checking - don't use a variable before defining it
 *
 * 2. LIVE VARIABLES (Backward, May Analysis)  
 *    Question: "Which variables MIGHT be used after this point?"
 *    Use case: Register allocation - if a variable is dead, we can reuse its slot
 *
 * THE FIXPOINT ALGORITHM:
 * -----------------------
 * Dataflow analysis is an iterative process:
 *
 *   1. Initialize all blocks with a starting state (TOP or BOTTOM)
 *   2. For each block, compute new IN/OUT based on neighbors
 *   3. If anything changed, repeat step 2
 *   4. When nothing changes, we've reached a "fixpoint" - done!
 *
 * This always terminates because:
 *   - We're working with finite sets (registers)
 *   - Updates are monotonic (sets only grow or shrink, never oscillate)
 *   - There's a maximum size (all registers) we can't exceed
 *)

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

(* =============================================================================
 * DEFINITE VARIABLES ANALYSIS (Forward, Must)
 * =============================================================================
 *
 * GOAL: At each program point, know which variables are DEFINITELY defined.
 *
 * "MUST" ANALYSIS
 * --------------------
 * This is a MUST analysis: we only mark a variable as "definitely defined"
 * if it's defined on ALL paths reaching this point.
 *
 * Example:
 *   Block 1: if (input > 0) goto Block 2 else goto Block 3
 *   Block 2: x = 5; goto Block 4
 *   Block 3: goto Block 4
 *   Block 4: output = x    // ERROR! x not defined on path 1->3->4
 *
 * At Block 4's entry, x is NOT definitely defined (path 1->3->4 skips it).
 *
 * THE ALGORITHM:
 * --------------
 * Direction: FORWARD (follow execution order)
 * Meet: INTERSECTION (∩) - a variable is definitely defined only if defined
 *       on ALL incoming paths
 * Transfer: OUT[B] = IN[B] ∪ Defined[B]
 *
 * INITIALIZATION: TOP (all registers)
 * Why start with "everything is defined"? Because we're computing a MUST
 * analysis via Greatest Fixed Point. Starting from TOP and shrinking down
 * ensures we only keep properties that are truly guaranteed.
 *
 * SPECIAL CASE: Entry block
 * At program entry, only r_in is defined (it's the input register).
 * Everything else is undefined.
 *
 * Computed Value: Set of definitely defined variables (registers)
 * Analysis State: Associate IN and OUT values to each block
 *   - IN[B]: variables defined at block entry
 *   - OUT[B]: variables defined at block exit
 * Local Update: OUT[B] = IN[B] ∪ Defined[B]
 * Global Update: IN[B] = ∩ OUT[P] for all predecessors P
 *)
module DefiniteVariables = struct
  (* Analysis State: maps block_id -> (IN, OUT) sets *)
  type analysis_result = {
    in_sets : RegisterSet.t BlockMap.t;
    out_sets : RegisterSet.t BlockMap.t;
  }

  (* ---------------------------------------------------------------------------
   * compute_defined: Extract Defined Registers from a Block
   * ---------------------------------------------------------------------------
   *
   * Returns the set of all registers that are WRITTEN by commands in this block.
   * This is the GEN set for definite variables analysis.
   *
   * EXAMPLE:
   *   Block: [add r1 r2 => r3; copy r3 => r4]
   *   Result: {r3, r4}
   *)
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

    (* Initialize: Each entry starts from TOP (all registers) This is a MUST
       analysis, so we use greatest fixpoint starting from TOP *)
    let init_state = BlockMap.mapi (fun _ _ -> all_regs) cfg.blocks in

    (* For each block, it computes registers defined at entry and exit. They are
       saved in the state: block_id -> {r_0, r_1, ...} *)
    let rec iterate iteration out_state =
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
    log_verbose verbose "Fixpoint reached after %d iterations" final_iteration;
    { in_sets = final_in; out_sets = final_out }

  (* ---------------------------------------------------------------------------
   * check_safety: Verify All Registers Are Initialized Before Use
   * ---------------------------------------------------------------------------
   *
   * Uses definite variables analysis to detect uninitialized register usage.
   * Returns true if the program is safe, false otherwise.
   *
   * ERROR DETECTION:
   * For each instruction, checks if all USE registers are in the definitely-
   * defined set at that point. If not, reports an error.
   *
   * EXAMPLE ERROR:
   *   Block 1: add r1 r2 => r3    // r2 undefined!
   *   Output: "Block 1: Register r2 used before definition"
   *)
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


(* =============================================================================
 * LIVE VARIABLES ANALYSIS (Backward, May)
 * =============================================================================
 *
 * GOAL: At each program point, know which variables MIGHT be used later.
 *
 * "MAY" ANALYSIS
 * --------------------
 * This is a MAY analysis: we mark a variable as "live" if it MIGHT be used
 * on ANY path from this point forward.
 *
 * Example:
 *   Block 1: x = 5; if (input > 0) goto Block 2 else goto Block 3
 *   Block 2: output = x; goto Block 4
 *   Block 3: output = 0; goto Block 4
 *   Block 4: halt
 *
 * At Block 1's exit, x is live because it's used in Block 2 (even though
 * Block 3 doesn't use it - it's used on at least ONE path).
 *
 * THE ALGORITHM:
 * --------------
 * Direction: BACKWARD (reverse execution order)
 * Meet: UNION (∪) - a variable is live if it's live on ANY outgoing path
 * Transfer: IN[B] = UpwardExposed[B] ∪ (OUT[B] - Killed[B])
 *   where:
 *     UpwardExposed[B] = variables used before being defined in B
 *     Killed[B] = variables defined in B
 *
 * INITIALIZATION: BOTTOM (empty set)
 * Why start with "nothing is live"? Because we're computing a MAY analysis
 * via Least Fixed Point. Starting from BOTTOM and growing up ensures we
 * discover all variables that might be live without being overly pessimistic.
 *
 * SPECIAL CASE: Exit block
 * At program exit, only r_out is live (it's the output register).
 * Everything else is dead.
 *
 * TWO-LEVEL PRECISION:
 * --------------------
 * We compute liveness at TWO granularities:
 *
 * 1. BLOCK-LEVEL: Liveness at block boundaries (IN/OUT sets)
 *    - Needed for correctness across control flow (branches, loops)
 *    - Uses iterative fixpoint algorithm
 *    - Gives us: "Which registers are live when entering/exiting this block?"
 *
 * 2. INSTRUCTION-LEVEL: Liveness after each instruction within blocks
 *    - Once block-level converges, propagate backward through instructions
 *    - Gives precise lifetimes for sequential code in same block
 *    - No iteration needed: simple backward walk
 *    - Gives us: "Which registers are live after executing instruction i?"
 *
 * WHY INSTRUCTION-LEVEL MATTERS:
 * -------------------------------
 * Block-level alone sees: "r1, r2, r3 all live somewhere in this block"
 * Instruction-level sees: "r1 dies at instr 2, r2 at instr 4, r3 at instr 6"
 *
 * This enables aggressive coalescing of sequential variables!
 *
 * Example:
 *   Instr 0: r1 = x + 1      // r1 born
 *   Instr 1: r2 = r1 + 2     // r1 dies (last use), r2 born
 *   Instr 2: r3 = r2 + 3     // r2 dies, r3 born
 *   Instr 3: out = r3        // r3 dies
 *
 * Block-level: r1, r2, r3 all appear to interfere
 * Instruction-level: r1, r2, r3 have disjoint lifetimes → can merge into 1 register!
 *
 * Computed Value: Set of live variables (registers)
 * Analysis State: Associate IN and OUT values to each block + instruction
 *   - IN[B]: variables live at block entry
 *   - OUT[B]: variables live at block exit
 *   - LIVE_AFTER[B, i]: variables live after instruction i in block B
 * Local Update: IN[B] = UpwardExposed[B] ∪ (OUT[B] - Killed[B])
 * Global Update: OUT[B] = ∪ IN[S] for all successors S
 * Instruction Update: LIVE_AFTER[B, i] = (LIVE_AFTER[B, i+1] - DEF[i]) ∪ USE[i]
 *)
module LiveVariables = struct
  (* Instruction point types are now in MiniRISCUtils (opened at top of file) *)

  (* Analysis result: both block-level and instruction-level liveness *)
  type analysis_result = {
    block_in : RegisterSet.t BlockMap.t; (* Live at block entry *)
    block_out : RegisterSet.t BlockMap.t; (* Live at block exit *)
    instr_after : RegisterSet.t InstrPointMap.t; (* Live after each instruction *)
  }

  (* Compute upward exposed uses and variables killed by this block *)
  let compute_local_info (block : risc_cfg_block) =
    let upward_exposed, killed =
      List.fold_left
        (fun (exposed, killed) cmd ->
          (* Get registers used and defined in this command *)
          let uses = get_used_registers cmd in
          let defs = get_defined_registers cmd in

          (* Upward exposed if it's used before being defined *)
          let new_exposed =
            List.fold_left
              (fun acc u ->
                (* Add to exposed if not already killed *)
                if RegisterSet.mem u killed then acc else RegisterSet.add u acc
              )
              exposed uses
          in
          (* Update killed set with newly defined registers *)
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
        (* Get registers used in the terminator *)
        let uses = get_used_registers term in
        (* Add upward exposed uses from terminator *)
        let final_exposed =
          List.fold_left
            (fun acc u ->
              if RegisterSet.mem u killed then acc else RegisterSet.add u acc
            )
            upward_exposed uses
        in
        (final_exposed, killed)

  (* -----------------------------------------------------------------------------
   * compute_instruction_level_liveness: Refine liveness within each block
   * -----------------------------------------------------------------------------
   * 
   * After block-level analysis converges, we know what's live at each block's
   * exit (OUT[block]). Now propagate backward through instructions to get 
   * precise lifetimes.
   *
   * For each block, start with OUT[block] and walk backward:
   *   - At each instruction i: live_after[i] = what's live after executing it
   *   - live_before[i] = (live_after[i] - def[i]) ∪ use[i]
   *   - Continue to previous instruction
   *)
  let compute_instruction_level_liveness cfg block_out_sets =
    BlockMap.fold
      (fun block_id block acc_map ->
        (* Get all instructions in this block (commands + terminator) *)
        let all_instrs =
          match block.terminator with
          | None -> block.commands
          | Some term -> block.commands @ [ term ]
        in

        let num_instrs = List.length all_instrs in

        (* Get OUT[block] - what's live when exiting this block *)
        let block_out =
          try BlockMap.find block_id block_out_sets
          with Not_found -> RegisterSet.empty
        in

        (* Walk backward through instructions from instruction index*)
        let rec backward_walk instr_idx current_live acc =
          if instr_idx < 0 then
            (* Reached beginning of block - record entry point *)
            (* Track what's live BEFORE first instruction *)
            let entry_point = (block_id, Entry) in
            InstrPointMap.add entry_point current_live acc
          else
            let instr = List.nth all_instrs instr_idx in

            (* Record: what's live AFTER this instruction *)
            let point = (block_id, AfterInstr instr_idx) in
            let updated_acc = InstrPointMap.add point current_live acc in

            let defs = get_defined_registers instr in
            let uses = get_used_registers instr in

            (* Compute what's live BEFORE this instruction for the next 
             * iteration. This will be what is currently live for the 
             * previous instruction (backward) *)
            let live_before =
              (* Remove defined registers from current live set *)
              let after_kill =
                List.fold_right RegisterSet.remove defs current_live
              in
              (* Build the live set without defined registers *)
              List.fold_right RegisterSet.add uses after_kill
            in

            (* Continue to previous instruction *)
            backward_walk (instr_idx - 1) live_before updated_acc
        in

        backward_walk (num_instrs - 1) block_out acc_map
      )
      cfg.blocks InstrPointMap.empty

  (* Main analysis: block-level first, then refine to instruction-level *)
  let analyze ?(verbose = false) (cfg : risc_cfg) : analysis_result =
    log_verbose verbose
      "\n=== LIVE VARIABLES ANALYSIS (Block + Instruction Level) ===";

    log_verbose verbose "Step 1: Block-level liveness (fixpoint iteration)";

    (* Initialize: all blocks have empty IN. Start from BOTTOM *)
    let init_in = BlockMap.map (fun _ -> RegisterSet.empty) cfg.blocks in

    (* Block-level analysis *)
    let rec iterate iteration in_sets =
      (* Compute IN and OUT sets for each block *)
      let new_in_sets, new_out_sets, changed =
        BlockMap.fold
          (fun id block (acc_in, acc_out, acc_changed) ->
            let succs = get_successors cfg id in

            (* OUT[B] = ∪ IN[S] for all successors S *)
            let out_value =
              (* Output register is live at exit if the block is the exit block *)
              if id = cfg.exit then RegisterSet.singleton output_register
              else
                (* Compute the union of IN sets of all successors *)
                List.fold_left
                  (fun acc (succ_id, _) ->
                    let succ_in =
                      try BlockMap.find succ_id in_sets
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

            let old_in = BlockMap.find id in_sets in
            let has_changed = not (RegisterSet.equal in_value old_in) in

            ( BlockMap.add id in_value acc_in,
              BlockMap.add id out_value acc_out,
              acc_changed || has_changed
            )
          )
          cfg.blocks
          (BlockMap.empty, BlockMap.empty, false)
      in

      if changed then iterate (iteration + 1) new_in_sets
      else (iteration, new_in_sets, new_out_sets)
    in

    let block_iterations, block_in_final, block_out_final = iterate 1 init_in in
    log_verbose verbose "  Block-level fixpoint reached after %d iterations"
      block_iterations;

    (* Instruction-level refinement (single backward pass per block) *)
    log_verbose verbose
      "Step 2: Instruction-level liveness (backward refinement)";
    let instr_liveness =
      compute_instruction_level_liveness cfg block_out_final
    in

    let num_instr_points = InstrPointMap.cardinal instr_liveness in
    log_verbose verbose "  Computed liveness for %d instruction points"
      num_instr_points;

    {
      block_in = block_in_final;
      block_out = block_out_final;
      instr_after = instr_liveness;
    }
end

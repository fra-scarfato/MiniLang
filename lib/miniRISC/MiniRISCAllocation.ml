open MiniRISCSyntax
open MiniRISCCFG
open MiniRISCUtils
module Dataflow = MiniRISCDataflow

(* =============================================================================
 * REGISTER ALLOCATION: THE CORE OPTIMIZATION PROBLEM
 * =============================================================================
 *
 * This module solves one of the most fundamental problems in compiler design:
 * mapping an unlimited number of "virtual" registers (from our intermediate
 * representation) down to a fixed, small number of physical registers in the
 * target CPU architecture.
 *
 * THE PROBLEM:
 * ------------
 * Our translation phase (MiniRISCTranslation) generates code that freely
 * allocates virtual registers like r0, r1, r2, ... r42, etc. But real CPUs
 * have limited registers. We need to:
 *
 *   1. Decide which virtual registers get physical registers
 *   2. Decide which virtual registers must live in memory
 *   3. Insert load/store instructions to move data between memory and registers
 *
 * OUR TWO-PHASE STRATEGY:
 * -----------------------
 * Phase 1 (Optional): REGISTER COALESCING
 *   - Merge virtual registers that never interfere (aren't live at same time)
 *   - Example: If r1 dies before r2 is born, merge them into one register
 *   - This reduces pressure on the limited physical registers
 *   - Pure optimization: doesn't change program behavior, just reduces waste
 *
 * Phase 2 (Required): ALLOCATION & SPILLING
 *   - Assign the most frequently-used registers to physical slots
 *   - Spill the rest to memory (starting at address 0x1000)
 *   - Rewrite the code to add load/store sequences for spilled variables
 *
 * WHY THIS ORDERING?
 * ------------------
 * We do coalescing BEFORE allocation because:
 *   - Fewer virtual registers = less pressure = fewer memory spills
 *   - It's easier to merge on the virtual level than after physical assignment
 *   - Dead code elimination happens naturally during coalescing
 *
 * ========== Register Allocation Architecture ========== *)
(*
   TARGET ARCHITECTURE WITH n TOTAL PHYSICAL REGISTERS:
   
   Physical Register Breakdown (all part of the n total):
   ┌────────────────────────────────────────────────────────────┐
   │ r_in             │ 1 register  │ Input register (special)   │
   │ r_out            │ 1 register  │ Output register (special)  │
   │ r_a, r_b         │ 2 registers │ Swap registers             │
   │ r0..r(n-5)       │ n-4 registers │ General-purpose          │
   └────────────────────────────────────────────────────────────┘
   Total: n physical registers
   
   Available for program variables: n - 4 registers
   
   Register Details:
   1. r_in, r_out (2 physical registers):
      - Part of the n total physical registers
      - Special I/O registers, never spilled to memory
      - Both r_in and r_out are NEVER merged (conservative approach for clear I/O semantics)
   
   2. r_a, r_b (2 physical registers):
      - Part of the n total physical registers
      - Swap/temporary registers for memory load/store operations
      - Only appear in code after spilling transformation
      - Cannot be spilled (they ARE the mechanism for accessing memory)
   
   3. General-purpose registers (n - 4 physical registers):
      - Part of the n total physical registers
      - Available for program variables
      - Most frequent variables allocated to these registers
      - Remaining variables spilled to memory
   
   EXAMPLE with n=8 total physical registers:
   - r_in, r_out: 2 physical registers (I/O, special)
   - r_a, r_b: 2 physical registers (swap)
   - r0, r1, r2, r3: 4 physical registers (general-purpose for variables)
   - Total: 8 physical registers
   - Variables beyond 4 most frequent → spilled to memory

   PIPELINE:
   Step 1 (Optional): Register Merging - Coalesce m registers → m' registers
   Step 2: Allocation & Spilling - Assign m' registers to (n-4) slots or memory
*)

(* ========== Logging Utility ========== *)
let log_verbose verbose fmt =
  Printf.ksprintf (fun s -> if verbose then print_endline s else ()) fmt

(* ========== Constants for Swap Registers ========== *)
(* These are used ONLY in Step 1.b (Spilling). They do not exist in Step 1. *)
let r_a = Register "r_a"
let r_b = Register "r_b"

(* =============================================================================
 * STEP 1: REGISTER COALESCING (Optional Optimization)
 * =============================================================================
 *
 * WHAT IS REGISTER COALESCING?
 * -----------------------------
 * Imagine we have this code:
 *   r1 = input
 *   r2 = r1 + 1
 *   [r1 is never used again]
 *   output = r2
 *
 * We allocated TWO registers (r1 and r2) but they're never alive at the same
 * time! We can merge them into a single register and eliminate the copy.
 *
 * INSTRUCTION-LEVEL LIVENESS FOR COALESCING:
 * -------------------------------------------
 * We now use instruction-level liveness (integrated into LiveVariables module)
 * which gives us precise, fine-grained lifetimes for each register.
 *
 * For each register, we build a live range = set of instruction points where
 * it's live. Two registers can be merged if their live ranges DON'T OVERLAP.
 *
 * This works excellently for sequential code:
 *   r1 = x + 1    // r1 live at points {0, 1}
 *   r2 = r1 + 2   // r2 live at points {1, 2}, r1 dead after point 1
 *   r3 = r2 + 3   // r3 live at points {2, 3}, r2 dead after point 2
 *
 * Since r1, r2, r3 have disjoint point sets, they can ALL merge!
 *
 * CRITICAL DESIGN DECISION: DON'T TOUCH I/O REGISTERS
 * ----------------------------------------------------
 * We NEVER merge r_in or r_out with anything else. Here's why:
 *
 * - SIMPLICITY: Treating them as sacred means we never have edge cases like
 *    "what if the output register gets spilled" or "what if input merges with
 *    a frequently-used variable that needs a physical register".
 *
 * - MISSED OPTIMIZATIONS ARE ACCEPTABLE: Yes, we might miss chances to
 *    eliminate copies like "r_out = r5". But the cost of one extra copy is
 *    tiny compared to the complexity of getting merge-with-spill correct.
 *)

module RangeMap = Map.Make (struct
  type t = register

  let compare = compare
end)

(* -----------------------------------------------------------------------------
 * compute_live_ranges_from_liveness: Build live ranges from analysis result
 * -----------------------------------------------------------------------------
 *
 * Takes the instruction-level liveness (map: instruction_point -> live_set)
 * and inverts it to get per-register live ranges (map: register -> point_set).
 *
 * If a register is in the live_set at a point, that point is in its live range.
 *)
let compute_live_ranges_from_liveness liveness_result =
  (* Iterate on the instruction points *)
  InstrPointMap.fold
    (fun point live_set acc ->
      (* Iterate on the registers live at this point *)
      RegisterSet.fold
        (fun reg range_map ->
          (* Get the current instruction points for this register*)
          let current_points =
            try RangeMap.find reg range_map
            with Not_found -> InstrPointSet.empty
          in
          (* Add the current point to the register's live range *)
          RangeMap.add reg
            (InstrPointSet.add point current_points)
            range_map
        )
        live_set acc
    )
    liveness_result.Dataflow.LiveVariables.instr_after RangeMap.empty

(* -----------------------------------------------------------------------------
 * ranges_interfere: Check if Two Live Ranges Overlap
 * -----------------------------------------------------------------------------
 *
 * Two registers interfere if they're both live at the same program point.
 * This means they can't share the same physical register.
 *
 * EXAMPLE:
 *   r1 live at: {(0,1), (0,2)}
 *   r2 live at: {(0,2), (0,3)}
 *   Result: true (they overlap at (0,2))
 *)
let ranges_interfere range1 range2 =
  not (InstrPointSet.is_empty (InstrPointSet.inter range1 range2))

(* -----------------------------------------------------------------------------
 * union_ranges: Merge Two Live Ranges
 * -----------------------------------------------------------------------------
 *
 * Combines the instruction points from two live ranges.
 * Used when merging registers into the same physical slot.
 *)
let union_ranges range1 range2 = InstrPointSet.union range1 range2

(* Merge registers with non-intersecting live ranges *)
let merge_registers ?(verbose = false) cfg =
  log_verbose verbose "\n=== STEP 1: REGISTER MERGING (COALESCING) ===";

  (* Run liveness analysis (block + instruction level) *)
  log_verbose verbose "Running liveness analysis (block + instruction level)";
  let liveness_result = Dataflow.LiveVariables.analyze ~verbose:false cfg in

  (* Build live ranges from instruction-level liveness *)
  let live_ranges = compute_live_ranges_from_liveness liveness_result in

  (* Get all registers sorted, excluding r_in and r_out from merging *)
  let all_regs =
    RangeMap.bindings live_ranges
    |> List.map fst
    |> List.filter (fun r -> r <> input_register && r <> output_register)
      (* r_in and r_out are never merged *)
    |> List.sort compare
  in

  log_verbose verbose "Total virtual registers (excluding r_in/r_out): %d"
    (List.length all_regs);
  log_verbose verbose
    "Note: r_in and r_out are never merged (always kept as special registers)";

  (* ---------------------------------------------------------------------------
   * GREEDY MERGING: The Heart of Coalescing
   * ---------------------------------------------------------------------------
   *
   * We process registers one by one, trying to merge each into an existing
   * "group" (represented by a single register). Think of it like Tetris:
   * we're trying to pack registers into groups without collisions.
   *
   * FOR EACH REGISTER:
   *   1. Look at all existing groups
   *   2. Find the FIRST group whose live range doesn't overlap with this register
   *   3. If found: Merge! Add this register to that group's range, mark rename
   *   4. If not found: Start a new group (this register becomes the representative)
   *
   * WHY GREEDY?
   * This isn't optimal - we might get a better packing with backtracking or
   * graph coloring algorithms. But those are complex and slow. For a compiler,
   * "good enough" is often better than "perfect but takes forever".
   *
   * THE RENAMING MAP:
   * We build a map: old_register -> representative_register
   * Example: {r2 -> r1, r5 -> r1, r7 -> r3}
   * This means r2 and r5 both got merged into r1's group, r7 into r3's group.
   * Later we'll walk the entire CFG and replace all mentions of r2 with r1.
   *)
  let _, renaming, merged_count =
    (* Iterate over all registers *)
    List.fold_left
      (fun (groups, renaming, count) reg ->
        (* Get the live range for this register *)
        let reg_range = RangeMap.find reg live_ranges in

        (* Try to find a group this register can fit into (non-interfering) *)
        (* Each group represents merged registers in a live range *)
        let valid_group =
          (* Iterate over existing groups *)
          RangeMap.fold
            (fun rep_reg group_range acc ->
              match acc with
              | Some _ -> acc (* Already found a valid group, skip *)
              | None ->
                  (* Not found yet *)
                  (* Check if the range of this register interferes with the group's range *)
                  if not (ranges_interfere reg_range group_range) then
                    (* If no interference, this group is valid so return the representative register*)
                    Some rep_reg
                  else None
            )
            groups None
        in

        match valid_group with
        | Some rep ->
            (* If found a valid group, merge the current register into the representative *)
            let new_range = union_ranges reg_range (RangeMap.find rep groups) in
            (* Update the group's live range to include the current register's range *)
            let new_groups = RangeMap.add rep new_range groups in
            (* Update the renaming map to indicate 'reg' is merged into 'rep' *)
            let new_renaming = RegisterMap.add reg rep renaming in
            log_verbose verbose "  Merging %s -> %s" (string_of_register reg)
              (string_of_register rep);
            (new_groups, new_renaming, count + 1)
        | None ->
            (* Start a new group with 'reg' *)
            let new_groups = RangeMap.add reg reg_range groups in
            (* Add the new group with itself as the representative *)
            let new_renaming = RegisterMap.add reg reg renaming in
            (new_groups, new_renaming, count)
      )
      (RangeMap.empty, RegisterMap.empty, 0)
      all_regs
  in

  log_verbose verbose "Total registers merged: %d" merged_count;

  (* ---------------------------------------------------------------------------
   * APPLYING THE RENAMING: Rewrite the entire CFG
   * ---------------------------------------------------------------------------
   *
   * Now that we've decided which registers merge together, we need to actually
   * rewrite all the code to use the merged names. If r5 merged into r2, every
   * instruction that used r5 must now use r2 instead.
   *
   * WHY NOT MODIFY IN PLACE?
   * We use a pure functional approach: build a NEW CFG with renamed registers
   * rather than mutating the old one. This is safer (no accidental aliasing
   * bugs) and more idiomatic in OCaml.
   *
   * THE RENAMING FUNCTION:
   * For each register in each instruction, look it up in the renaming map.
   * If it's there (it got merged), use the representative. If not (it's a
   * group representative or wasn't merged), keep it as-is.
   *
   * EDGE CASE: What if we merged zero registers?
   * This can happen if all registers interfere (no optimization possible).
   * In that case, return the original CFG unchanged - no point rebuilding it.
   *)
  if merged_count = 0 then cfg
  else
    let final_blocks =
      BlockMap.map
        (fun block ->
          let map_lookup r =
            try RegisterMap.find r renaming with Not_found -> r
          in
          (* Rewrite each command with renamed registers *)
          let rename_cmd = function
            | BinRegOp (op, r1, r2, rd) ->
                BinRegOp (op, map_lookup r1, map_lookup r2, map_lookup rd)
            | BinImmOp (op, r1, n, rd) ->
                BinImmOp (op, map_lookup r1, n, map_lookup rd)
            | UnaryOp (op, r1, rd) -> UnaryOp (op, map_lookup r1, map_lookup rd)
            | Load (r1, r2) -> Load (map_lookup r1, map_lookup r2)
            | LoadI (n, r) -> LoadI (n, map_lookup r)
            | Store (r1, r2) -> Store (map_lookup r1, map_lookup r2)
            | CJump (r, l1, l2) -> CJump (map_lookup r, l1, l2)
            | c -> c
          in
          let cmds = List.map rename_cmd block.commands in
          let term = Option.map rename_cmd block.terminator in
          { block with commands = cmds; terminator = term }
        )
        cfg.blocks
    in
    { cfg with blocks = final_blocks }

(* =============================================================================
 * STEP 2: ALLOCATION & SPILLING
 * =============================================================================
 *
 * After coalescing (if enabled), we have m' virtual registers. Now we must map
 * them to the n-4 available physical register slots. The registers that don't
 * fit get "spilled" to memory.
 *
 * THE ALLOCATION STRATEGY: FREQUENCY-BASED GREEDY
 * ------------------------------------------------
 * 1. Count how many times each register is used (frequency)
 * 2. Sort registers by frequency (most-used first)
 * 3. The top (n-4) registers get physical slots (r0, r1, ...)
 * 4. The rest get memory addresses (0x1000, 0x1001, ...)
 *
 * WHY FREQUENCY?
 * Hot registers (used in loops, computed repeatedly) benefit most from
 * being in a physical register. Cold registers (used once at the start)
 * don't hurt as much if they're in memory. This is a heuristic, not optimal,
 * but it works well in practice.
 *
 * THE MEMORY ADDRESS SCHEME: 0x1000 BASE
 * ---------------------------------------
 * We could use addresses 0, 1, 2, ... but then how do you distinguish:
 *   loadi 0 => r1    (load the constant zero)
 *   loadi 0 => r1    (load from memory address zero)
 *
 * Using 0x1000 (4096) as a base makes spilled addresses obviously different
 * from small integer constants. It's a visual/debugging aid more than a
 * semantic requirement.
 *
 * CRITICAL INSIGHT: THE SWAP REGISTERS
 * ------------------------------------
 * When we spill r5 to memory address 0x1001, we can't just write:
 *   add r1 r2 => [0x1001]
 *
 * The RISC architecture doesn't support memory operands! We need registers
 * for EVERYTHING. So we reserve two registers (r_a and r_b) as "scratch
 * space" for the spilling machinery:
 *
 *   loadi 0x1001 => r_a   // Load the address
 *   load r_a => r_a        // Load the value from that address
 *   add r1 r2 => r_a       // Now we can compute
 *   loadi 0x1001 => r_b    // Load address again (for store)
 *   store r_a => r_b       // Write result back
 *
 * This is why we have n-4 slots, not n-2: two for I/O, two for swapping.
 *)

type location = InRegister of register | InMemory of int

(* Memory address base - offsets addresses to distinguish them from regular
   integers *)
let memory_base_addr = 0x1000 (* 4096 in decimal *)

(* -----------------------------------------------------------------------------
 * get_frequencies: Count how "hot" each register is
 * -----------------------------------------------------------------------------
 *
 * To decide which registers to keep in physical slots vs. spill to memory,
 * we need a metric. The simplest and most effective is USE FREQUENCY:
 * how many times does this register appear in the code?
 *
 * We count BOTH uses and definitions:
 *   add r1 r2 => r3    // r1: +1, r2: +1, r3: +1
 *
 * Why count definitions? Because writing to memory is also slow! A register
 * that's written to 100 times should stay in a physical register just like
 * one that's read 100 times.
 *
 * ALTERNATIVE METRICS WE DIDN'T USE:
 *   - Loop depth: Weigh instructions inside loops higher
 *   - Critical path: Prioritize registers on the longest execution path  
 *   - Graph coloring: Use interference graph structure
 *
 * These are more sophisticated but also more complex. For an educational
 * compiler, simple frequency works surprisingly well.
 *)
let get_frequencies cfg =
  let incr map r =
    (* Get the current count for register r, defaulting to 0 if not found *)
    let c = try RegisterMap.find r map with Not_found -> 0 in
    (* Increment the count for register r *)
    RegisterMap.add r (c + 1) map
  in
  BlockMap.fold
    (fun _ block acc ->
      (* Flatten commands and terminator into a single list *)
      let cmds = block.commands @ Option.to_list block.terminator in
      (* Iterate over each command to count register usage *)
      List.fold_left
        (fun acc cmd ->
          (* Iterate over each register used or defined in the command and increment its count *)
          List.fold_left incr acc
            (get_used_registers cmd @ get_defined_registers cmd)
        )
        acc cmds
    )
    cfg.blocks RegisterMap.empty

let allocate_locations ?(verbose = false) cfg n_target =
  log_verbose verbose "\n=== STEP 2: ALLOCATION & SPILLING ===";
  log_verbose verbose "Total physical registers available: n = %d" n_target;

  if n_target < 4 then
    failwith "Target must have >= 4 registers (r_in, r_out, r_a, r_b)";

  (* Of the n total physical registers: 
    - 1 is r_in (input, special) 
    - 1 is r_out (output, special) 
    - 2 are r_a, r_b (swap registers) 
    - Remaining n-4 are available for general-purpose program variables 
  *)
  let available_slots = n_target - 4 in

  log_verbose verbose "  Physical register allocation:";
  log_verbose verbose
    "    - r_in, r_out: 2 registers (I/O, always in registers)";
  log_verbose verbose
    "    - r_a, r_b: 2 registers (swap, for spilling operations)";
  log_verbose verbose
    "    - General-purpose: %d registers (for program variables)"
    available_slots;

  let freqs = get_frequencies cfg in

  (* ---------------------------------------------------------------------------
   * THE ALLOCATION DECISION: Who stays, who goes?
   * ---------------------------------------------------------------------------
   * 
   * 1. Sort all program registers by frequency (hottest first)
   * 2. The first (n-4) registers get physical slots
   * 3. The rest get memory addresses starting at 0x1000
   *
   * EXAMPLE: n=8 (so 4 available slots), 6 program registers
   *   r1: frequency 50  -> Physical slot (r2)
   *   r2: frequency 45  -> Physical slot (r3)  
   *   r3: frequency 40  -> Physical slot (r4)
   *   r4: frequency 35  -> Physical slot (r5)
   *   r5: frequency 10  -> Memory (0x1000)
   *   r6: frequency 5   -> Memory (0x1001)
   *
   * WHAT ABOUT I/O REGISTERS?
   * They're added to the allocation map AFTER this, always as InRegister.
   * They're never in the frequency list because we filter them out early.
   *)
  (* Get program registers (exclude special I/O and swap registers) sorted by frequency *)
  let sorted_bindings =
    RegisterMap.bindings freqs
    |> List.filter (fun (reg, _) ->
        reg <> input_register && reg <> output_register && reg <> r_a
        && reg <> r_b
    )
    |> List.sort (fun (_, c1) (_, c2) -> compare c2 c1)
  in
  let sorted = List.map fst sorted_bindings in

  (* Allocation: most frequent variables get physical registers, 
     rest go to memory *)
  let alloc_map, next_mem_addr =
    (* Iterate over the sorted registers and their indices *)
    List.fold_left
      (fun (map, next_addr) (idx, reg) ->
        if idx < available_slots then (
          (* Fits in one of the (n-4) general-purpose physical registers *)
          log_verbose verbose "  [Reg] %s (freq=%d)" (string_of_register reg)
            (RegisterMap.find reg freqs);
          (* Add to allocation map as InRegister *)
          (RegisterMap.add reg (InRegister reg) map, next_addr)
        )
        else
          (* Spilled to memory - use offset address *)
          let mem_addr = memory_base_addr + next_addr in
          log_verbose verbose "  [Mem@0x%x] %s (freq=%d)" mem_addr
            (string_of_register reg)
            (RegisterMap.find reg freqs);
          (* Add to allocation map as InMemory and increment next_addr *)
          (RegisterMap.add reg (InMemory mem_addr) map, next_addr + 1)
      )
      (RegisterMap.empty, 0)
      (List.mapi (fun i r -> (i, r)) sorted)
  in

  (* Add I/O registers (always in physical registers) *)
  let alloc_map =
    alloc_map
    |> RegisterMap.add input_register (InRegister input_register)
    |> RegisterMap.add output_register (InRegister output_register)
  in

  log_verbose verbose "Summary: %d in registers, %d spilled"
    (min (List.length sorted) available_slots)
    next_mem_addr;
  alloc_map
(* =============================================================================
 * STEP 3: CODE REWRITING - The Spilling Machinery  
 * =============================================================================
 *
 * Now that we know which registers are in memory, we must rewrite every
 * instruction to handle them. This is the most delicate part of register
 * allocation - get it wrong and you silently corrupt your program.
 *
 * THE REWRITING RULES:
 * --------------------
 * For each instruction, we check the allocation map:
 *
 * 1. SOURCE OPERANDS (things we read):
 *    - If InRegister(r): Use r directly
 *    - If InMemory(addr): Load it into r_a first:
        loadi addr => r_a
        load r_a => r_a
 *
 * 2. DESTINATION OPERANDS (things we write):
 *    - If InRegister(r): Write to r directly
 *    - If InMemory(addr): Compute to r_b, then store:
        [computation] => r_b
        loadi addr => r_a  
        store r_b => r_a
 *
 * CRITICAL: WHY DIFFERENT REGISTERS FOR LOAD/STORE?
 * ---------------------------------------------------
 * Consider: add r1 r2 => r3, where r1 and r3 are both spilled.
 *
 * WRONG (using r_a for everything):
 *   loadi 0x1000 => r_a    // Load r1 from memory
 *   load r_a => r_a         // r_a now contains r1's value
 *   add r_a r2 => r_a       // Compute, result in r_a
 *   loadi 0x1001 => r_a    // Load r3's address... OVERWRITES THE RESULT!
 *   store r_a => r_a        // We just stored the address, not the value!
 *
 * RIGHT (using r_b for destination):
 *   loadi 0x1000 => r_a    // Load r1's address
 *   load r_a => r_a         // r_a = r1's value
 *   add r_a r2 => r_b       // Compute to r_b (keeping r_a safe)
 *   loadi 0x1001 => r_a    // Load r3's address into r_a (r_b still has result)
 *   store r_b => r_a        // Store r_b's value to address in r_a
 *
 * This is why we need TWO swap registers, not one.
 *)
(* ========== Code Rewriting Logic ========== *)

let load_if_needed map reg temp_reg =
  match RegisterMap.find_opt reg map with
  | Some (InRegister r) -> ([], r)
  | Some (InMemory addr) ->
      ([ LoadI (addr, temp_reg); Load (temp_reg, temp_reg) ], temp_reg)
  | None -> ([], reg)

let store_if_needed map reg val_reg addr_temp_reg =
  match RegisterMap.find_opt reg map with
  | Some (InMemory addr) ->
      [ LoadI (addr, addr_temp_reg); Store (val_reg, addr_temp_reg) ]
  | _ -> []

let rewrite_block alloc_map block =
  let rewrite_cmd = function
    | BinRegOp (op, r1, r2, rd) ->
        let l1, t1 = load_if_needed alloc_map r1 r_a in
        let l2, t2 = load_if_needed alloc_map r2 r_b in

        (* Determine destination based on allocation *)
        let rd_alloc = RegisterMap.find_opt rd alloc_map in
        let op_dest, stores =
          match rd_alloc with
          | Some (InRegister phys_reg) ->
              (* Destination is in a physical register, use it directly *)
              (phys_reg, [])
          | Some (InMemory _) ->
              (* Destination is spilled: compute to r_b, then store using r_a
                 for address *)
              (r_b, store_if_needed alloc_map rd r_b r_a)
          | None ->
              (* Not in allocation map: shouldn't happen, use original *)
              (rd, [])
        in

        l1 @ l2 @ [ BinRegOp (op, t1, t2, op_dest) ] @ stores
    | UnaryOp (op, r1, rd) ->
        let l1, t1 = load_if_needed alloc_map r1 r_a in

        let rd_alloc = RegisterMap.find_opt rd alloc_map in
        let op_dest, stores =
          match rd_alloc with
          | Some (InRegister phys_reg) -> (phys_reg, [])
          | Some (InMemory _) -> (r_b, store_if_needed alloc_map rd r_b r_a)
          | None -> (rd, [])
        in

        l1 @ [ UnaryOp (op, t1, op_dest) ] @ stores
    | BinImmOp (op, r1, imm, rd) ->
        let l1, t1 = load_if_needed alloc_map r1 r_a in

        let rd_alloc = RegisterMap.find_opt rd alloc_map in
        let op_dest, stores =
          match rd_alloc with
          | Some (InRegister phys_reg) -> (phys_reg, [])
          | Some (InMemory _) -> (r_b, store_if_needed alloc_map rd r_b r_a)
          | None -> (rd, [])
        in

        l1 @ [ BinImmOp (op, t1, imm, op_dest) ] @ stores
    | LoadI (imm, rd) ->
        let rd_alloc = RegisterMap.find_opt rd alloc_map in
        let op_dest, stores =
          match rd_alloc with
          | Some (InRegister phys_reg) -> (phys_reg, [])
          | Some (InMemory _) -> (r_b, store_if_needed alloc_map rd r_b r_a)
          | None -> (rd, [])
        in

        [ LoadI (imm, op_dest) ] @ stores
    | Load (addr, rd) ->
        let la, ta = load_if_needed alloc_map addr r_a in

        let rd_alloc = RegisterMap.find_opt rd alloc_map in
        let op_dest, stores =
          match rd_alloc with
          | Some (InRegister phys_reg) -> (phys_reg, [])
          | Some (InMemory _) ->
              (* addr uses r_a, so use r_b for result, then r_a for store
                 address *)
              (r_b, store_if_needed alloc_map rd r_b r_a)
          | None -> (rd, [])
        in

        la @ [ Load (ta, op_dest) ] @ stores
    | Store (src, addr) ->
        let ls, ts = load_if_needed alloc_map src r_a in
        let la, ta = load_if_needed alloc_map addr r_b in
        ls @ la @ [ Store (ts, ta) ]
    | cmd -> [ cmd ]
  in

  let final_cmds = List.concat_map rewrite_cmd block.commands in

  let term_cmds, new_term =
    match block.terminator with
    | Some (CJump (cond, l1, l2)) ->
        let l, t = load_if_needed alloc_map cond r_a in
        (l, Some (CJump (t, l1, l2)))
    | t -> ([], t)
  in

  { block with commands = final_cmds @ term_cmds; terminator = new_term }

(* ========== Report Memory-Allocated Registers ========== *)

(* Create a mapping from register names to memory addresses *)
let create_register_to_memory_map alloc_map =
  RegisterMap.fold
    (fun reg loc acc ->
      match loc with
      | InMemory addr -> RegisterMap.add reg addr acc
      | InRegister _ -> acc
    )
    alloc_map RegisterMap.empty

let report_memory_allocations ?(verbose = false) alloc_map =
  let memory_regs =
    RegisterMap.fold
      (fun reg loc acc ->
        match loc with
        | InMemory addr -> (reg, addr) :: acc
        | InRegister _ -> acc
      )
      alloc_map []
    |> List.sort (fun (_, a1) (_, a2) -> compare a1 a2)
  in

  if verbose && memory_regs <> [] then (
    log_verbose verbose "\n=== MEMORY ALLOCATION MAP ===";
    List.iter
      (fun (reg, addr) ->
        log_verbose verbose "  %s -> 0x%x" (string_of_register reg) addr
      )
      memory_regs
  );

  (* Return the mapping *)
  create_register_to_memory_map alloc_map

(* ========== Main Entry Point ========== *)

let allocate_registers ?(optimize = false) ?(verbose = false) n_target cfg =
  log_verbose verbose "\n=== REGISTER ALLOCATION (n=%d, optimize=%b) ==="
    n_target optimize;

  (* Register Merging (Optional Optimization) *)
  let merged_cfg = if optimize then merge_registers ~verbose cfg else cfg in

  (* Allocation & Spilling *)
  let alloc_map = allocate_locations ~verbose merged_cfg n_target in

  (* Code Rewriting *)
  let rewritten_blocks =
    BlockMap.map (rewrite_block alloc_map) merged_cfg.blocks
  in
  let final_cfg = { merged_cfg with blocks = rewritten_blocks } in

  (* Report final allocation *)
  let _ = report_memory_allocations ~verbose alloc_map in

  log_verbose verbose "";
  final_cfg

open MiniRISCSyntax
open MiniRISCCFG
open MiniRISCUtils
open MiniRISCDataflow

(* ========== Register Allocation with Memory Spilling ========== *)

type location = InRegister of register | InMemory of int

(* Physical register layout for n total registers: - r_in (input) - r_out
   (output) - r0, r1, ..., r(n-5) (n-4 general purpose registers) - r(n-4) = r_a
   (swap register A) - r(n-3) = r_b (swap register B) *)

(* Get the two swap registers based on target count *)
let r_a = Register "r_a"
let r_b = Register "r_b"

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
            (get_used_registers cmd @ get_defined_registers cmd)
        )
        acc cmds
    )
    cfg.blocks RegisterMap.empty

(* Allocate registers to physical locations Strategy: - r_in and r_out always
   get physical registers (don't count against limit) - Top (n-4) most
   frequently used variables get physical registers - Remaining variables
   spilled to memory *)
let allocate_locations ?(verbose = false) cfg n_target =
  log_verbose verbose "\n=== Register Allocation ===";
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
    List.iter
      (fun (Register name, count) -> Printf.printf "  %s: %d uses\n" name count)
      sorted;

  let sorted_regs = List.map fst sorted in

  (* Available slots: n total - 2 for in/out - 2 for r_a/r_b = n-4 *)
  let available_slots = max 0 (n_target - 4) in
  log_verbose verbose "\nAvailable slots for general registers: %d"
    available_slots;

  log_verbose verbose "\n--- Allocation Decisions ---";

  (* Allocate: r_in and r_out get registers, then top (n-4) by frequency *)
  let alloc_map, next_mem_addr, _ =
    List.fold_left
      (fun (map, next_addr, slots_used) reg ->
        if reg = input_register || reg = output_register then
          (* Always allocate r_in/r_out to registers *)
          let () =
            log_verbose verbose "  %s -> %s (special register)"
              (string_of_register reg) (string_of_register reg)
          in
          (RegisterMap.add reg (InRegister reg) map, next_addr, slots_used)
        else if slots_used < available_slots then
          (* Allocate to physical register *)
          let () =
            log_verbose verbose "  %s -> Physical register (slot %d/%d)"
              (string_of_register reg) (slots_used + 1) available_slots
          in
          (RegisterMap.add reg (InRegister reg) map, next_addr, slots_used + 1)
        else
          (* Spill to memory *)
          let () =
            log_verbose verbose "  %s -> Memory[%d] (spilled)"
              (string_of_register reg) next_addr
          in
          ( RegisterMap.add reg (InMemory next_addr) map,
            next_addr + 1,
            slots_used
          )
      )
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
      ([ LoadI (addr, temp_reg); Load (temp_reg, temp_reg) ], temp_reg)
  | None -> ([], reg)

(* Store a register to memory if needed and if it's live *)
let store_if_needed map reg val_reg addr_temp_reg is_live =
  match RegisterMap.find_opt reg map with
  | Some (InMemory addr) when is_live ->
      [ LoadI (addr, addr_temp_reg); Store (val_reg, addr_temp_reg) ]
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
            Printf.printf "  Dead store eliminated for %s\n"
              (string_of_register rd);

          (l1 @ l2 @ [ BinRegOp (op, t1, t2, op_dest) ] @ stores, eliminated)
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
            Printf.printf "  Dead store eliminated for %s\n"
              (string_of_register rd);

          (l1 @ [ UnaryOp (op, t1, op_dest) ] @ stores, eliminated)
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
            Printf.printf "  Dead store eliminated for %s\n"
              (string_of_register rd);

          (l1 @ [ BinImmOp (op, t1, imm, op_dest) ] @ stores, eliminated)
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
            Printf.printf "  Dead store eliminated for %s\n"
              (string_of_register rd);

          ([ LoadI (imm, op_dest) ] @ stores, eliminated)
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
            Printf.printf "  Dead store eliminated for %s\n"
              (string_of_register rd);

          (la @ [ Load (ta, op_dest) ] @ stores, eliminated)
      | Store (src, addr) ->
          let ls, ts = load_if_needed alloc_map src r_a in
          let la, ta = load_if_needed alloc_map addr r_b in
          (ls @ la @ [ Store (ts, ta) ], false)
      | _ -> ([ cmd ], false)
    in

    (* Update liveness backwards: In = (Out - Def) ∪ Use *)
    let uses = get_used_registers cmd in
    let defs = get_defined_registers cmd in
    let live_before =
      let after_kill = RegisterSet.diff live_after (RegisterSet.of_list defs) in
      RegisterSet.union after_kill (RegisterSet.of_list uses)
    in

    ( rewritten_cmds @ acc_cmds,
      live_before,
      stores_eliminated + if store_eliminated then 1 else 0
    )
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

  { block with commands = final_cmds @ term_cmds; terminator = new_term }

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
          List.fold_right RegisterSet.add (used @ defined) acc
        )
        acc cmds
    )
    cfg.blocks RegisterSet.empty

(* Sort registers with priority ordering *)
let sort_registers registers =
  let input_reg, rest1 = List.partition (( = ) input_register) registers in
  let output_reg, rest2 = List.partition (( = ) output_register) rest1 in
  let swap_regs, others = List.partition (fun r -> r = r_a || r = r_b) rest2 in
  (* Order: r_in, r_out, others, swaps *)
  input_reg @ output_reg @ others @ swap_regs

(* Create renaming map: virtual -> physical *)
let create_renaming_map ?(verbose = false) cfg n_target =
  log_verbose verbose "\n=== REGISTER RENAMING ===";

  let registers = RegisterSet.elements (collect_registers cfg) in
  let sorted = sort_registers registers in

  log_verbose verbose "Total unique registers: %d" (List.length registers);
  log_verbose verbose "\n--- Renaming Map ---";

  let _, map =
    List.fold_left
      (fun (idx, map) reg ->
        (* Special handling for in/out/swap registers *)
        if reg = input_register then
          let () =
            log_verbose verbose "  %s -> r_in" (string_of_register reg)
          in
          (idx, RegisterMap.add reg input_register map)
        else if reg = output_register then
          let () =
            log_verbose verbose "  %s -> r_out" (string_of_register reg)
          in
          (idx, RegisterMap.add reg output_register map)
        else if reg = r_a then
          let new_name = "r" ^ string_of_int (n_target - 4) in
          let () =
            log_verbose verbose "  %s -> %s (swap A)" (string_of_register reg)
              new_name
          in
          (idx, RegisterMap.add reg (Register new_name) map)
        else if reg = r_b then
          let new_name = "r" ^ string_of_int (n_target - 3) in
          let () =
            log_verbose verbose "  %s -> %s (swap B)" (string_of_register reg)
              new_name
          in
          (idx, RegisterMap.add reg (Register new_name) map)
        else
          (* General purpose registers: r0, r1, ..., r(n-5) *)
          let new_name = "r" ^ string_of_int idx in
          let () =
            log_verbose verbose "  %s -> %s" (string_of_register reg) new_name
          in
          (idx + 1, RegisterMap.add reg (Register new_name) map)
      )
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
        ( op,
          rename_register map r1,
          rename_register map r2,
          rename_register map rd
        )
  | BinImmOp (op, r1, imm, rd) ->
      BinImmOp (op, rename_register map r1, imm, rename_register map rd)
  | UnaryOp (op, r1, rd) ->
      UnaryOp (op, rename_register map r1, rename_register map rd)
  | Load (r1, r2) -> Load (rename_register map r1, rename_register map r2)
  | LoadI (imm, r) -> LoadI (imm, rename_register map r)
  | Store (r1, r2) -> Store (rename_register map r1, rename_register map r2)
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
        { block with commands = new_commands; terminator = new_terminator }
      )
      cfg.blocks
  in
  { cfg with blocks = new_blocks }

(* --- Main Entry Points --- *)

(* Register allocation with liveness analysis (optimized) *)
let reduce_registers_optimized ?(verbose = false) n cfg =
  if n < 4 then
    failwith "Target registers must be >= 4 (need r_in, r_out, r_a, r_b)";

  log_verbose verbose "\n=== Register Reduction (Optimized) ===";
  log_verbose verbose "Target: %d registers" n;

  let alloc_map = allocate_locations ~verbose cfg n in
  let liveness = LiveVariables.analyze ~verbose cfg in

  log_verbose verbose "\n--- Code Rewriting ---";
  let new_blocks =
    BlockMap.mapi
      (fun id block ->
        (* Compute live-out for this block *)
        let live_out_at_end =
          let succs = get_successors cfg id in
          if id = cfg.exit then RegisterSet.singleton output_register
          else
            List.fold_left
              (fun acc (sid, _) ->
                RegisterSet.union acc
                  ( try BlockMap.find sid liveness
                    with Not_found -> RegisterSet.empty
                  )
              )
              RegisterSet.empty succs
        in
        rewrite_block ~verbose r_a r_b alloc_map block live_out_at_end
      )
      cfg.blocks
  in

  (* Apply renaming to get final physical register names *)
  let final_cfg = rename_cfg ~verbose n { cfg with blocks = new_blocks } in

  log_verbose verbose "\n=== REGISTER REDUCTION COMPLETE ===\n";
  final_cfg

(* Register allocation without liveness (conservative, always stores) *)
let reduce_registers_no_opt ?(verbose = false) n cfg =
  if n < 4 then failwith "Target registers must be >= 4";

  log_verbose verbose "\n=== Register Reduction (Simple) ===";
  log_verbose verbose "Target: %d registers" n;

  let alloc_map = allocate_locations ~verbose cfg n in

  (* Conservative: assume all registers are always live *)
  let all_live = get_all_registers cfg in

  log_verbose verbose "\n--- Code Rewriting (No liveness) ---";
  let new_blocks =
    BlockMap.mapi
      (fun _ block -> rewrite_block ~verbose r_a r_b alloc_map block all_live)
      cfg.blocks
  in

  (* Apply renaming to get final physical register names *)
  let final_cfg = rename_cfg ~verbose n { cfg with blocks = new_blocks } in

  log_verbose verbose "\n=== REGISTER REDUCTION COMPLETE ===\n";
  final_cfg

let allocate_registers ?(optimize = false) ?(verbose = false) n cfg =
  if optimize then reduce_registers_optimized ~verbose n cfg
  else reduce_registers_no_opt ~verbose n cfg

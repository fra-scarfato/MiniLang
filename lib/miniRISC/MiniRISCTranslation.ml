open MiniImpSyntax
open MiniRISCSyntax
open MiniRISCUtils

(* =============================================================================
 * MINIIMP TO MINIRICS TRANSLATION: From High-Level to Low-Level
 * =============================================================================
 *
 * This module is the "compiler" phase that translates from MiniImp (with
 * variables, expressions, control flow) down to MiniRISC (pure register
 * operations, no variables, explicit jumps).
 *
 * THE TRANSLATION STRATEGY:
 * -------------------------
 * We use a "compute and copy" approach:
 *   1. Expressions compute results into FRESH temporary registers
 *   2. Assignments copy those results into the target variable's register
 *
 * This creates extra copy instructions, but it's simple and avoids a nasty
 * bug we encountered: if we tried to compute directly into the destination,
 * loops would break (the loop header reads the old value, but the body
 * overwrites it before the branch back).
 *
 * OPTIMIZATION: We do constant folding and algebraic simplification during
 * translation. Why? Because it's easier to optimize "x * 0" while we can
 * still see it's a multiplication, rather than after we've generated:
 *   loadi 0 => r1
 *   mult r2 r1 => r3
 * and trying to recognize that pattern.
 *
 * THE VARIABLE MAPPING:
 * ---------------------
 * We maintain a map: variable_name -> register_name
 *   "x" -> r5
 *   "counter" -> r12
 *
 * Special cases:
 *   - Input variable always maps to r_in
 *   - Output variable always maps to r_out
 *
 * This ensures the calling convention is stable: the test harness knows
 * where to put inputs and read outputs.
 *)

(* ========== Variable to Register Mapping ========== *)

module VarMap = Map.Make (String)

type context = {
  var_to_reg : register VarMap.t; (* variable name -> register *)
  next_reg : int;
  input_var : string; (* name of input parameter *)
  output_var : string; (* name of output parameter *)
  all_registers : register list; (* track all allocated registers *)
}

(* ========== Expression Translation with Optimizations ========== *)

(* Helper to allocate a new register and track it *)
let allocate_register ctx =
  let r = make_register ctx.next_reg in
  let ctx' =
    {
      ctx with
      next_reg = ctx.next_reg + 1;
      all_registers = r :: ctx.all_registers;
    }
  in
  (ctx', r)

(* Translate operations with constant folding and algebraic simplification *)
let rec trans_op ctx = function
  | Constant n ->
      let ctx', r = allocate_register ctx in
      (ctx', r, [ LoadI (n, r) ])
  | Variable v -> (
      if
        (* Check if it's input/output variable or regular variable *)
        v = ctx.input_var
      then (ctx, input_register, [])
      else if v = ctx.output_var then (ctx, output_register, [])
      else
        match VarMap.find_opt v ctx.var_to_reg with
        | Some r -> (ctx, r, [])
        | None ->
            (* First use of variable - allocate a register *)
            let ctx', r = allocate_register ctx in
            let ctx'' =
              { ctx' with var_to_reg = VarMap.add v r ctx'.var_to_reg }
            in
            (ctx'', r, []) (* ===== ALGEBRAIC SIMPLIFICATION FOR PLUS ===== *)
    )
  (* Identity: x + 0 = x *)
  | Plus (op, Constant 0) | Plus (Constant 0, op) -> trans_op ctx op
  (* Constant folding: c1 + c2 *)
  | Plus (Constant n1, Constant n2) ->
      let ctx', r = allocate_register ctx in
      (ctx', r, [ LoadI (n1 + n2, r) ])
  (* General case *)
  | Plus (op1, op2) ->
      let ctx, r1, c1 = trans_op ctx op1 in
      let ctx, r2, c2 = trans_op ctx op2 in
      let ctx', r = allocate_register ctx in
      (ctx', r, c1 @ c2 @ [ BinRegOp (Add, r1, r2, r) ])
  (* ===== ALGEBRAIC SIMPLIFICATION FOR MINUS ===== *)
  (* Identity: x - 0 = x *)
  | Minus (op, Constant 0) -> trans_op ctx op
  (* Constant folding: c1 - c2 *)
  | Minus (Constant n1, Constant n2) ->
      let ctx', r = allocate_register ctx in
      (ctx', r, [ LoadI (n1 - n2, r) ])
  (* General case *)
  | Minus (op1, op2) ->
      let ctx, r1, c1 = trans_op ctx op1 in
      let ctx, r2, c2 = trans_op ctx op2 in
      let ctx', r = allocate_register ctx in
      (ctx', r, c1 @ c2 @ [ BinRegOp (Sub, r1, r2, r) ])
  (* ===== ALGEBRAIC SIMPLIFICATION FOR TIMES ===== *)
  (* Identity: x * 1 = x *)
  | Times (op, Constant 1) | Times (Constant 1, op) -> trans_op ctx op
  (* Annihilation: x * 0 = 0 *)
  | Times (_, Constant 0) | Times (Constant 0, _) -> trans_op ctx (Constant 0)
  (* Constant folding: c1 * c2 *)
  | Times (Constant n1, Constant n2) ->
      let ctx', r = allocate_register ctx in
      (ctx', r, [ LoadI (n1 * n2, r) ])
  (* General case *)
  | Times (op1, op2) ->
      let ctx, r1, c1 = trans_op ctx op1 in
      let ctx, r2, c2 = trans_op ctx op2 in
      let ctx', r = allocate_register ctx in
      (ctx', r, c1 @ c2 @ [ BinRegOp (Mult, r1, r2, r) ])

(* Translate boolean expressions with optimizations *)
let rec trans_bool ctx = function
  | Bool b ->
      let ctx', r = allocate_register ctx in
      (ctx', r, [ LoadI ((if b then 1 else 0), r) ])
  (* ===== ALGEBRAIC SIMPLIFICATION FOR BOOLEANS ===== *)
  (* Constant folding for And *)
  | And (Bool false, _) | And (_, Bool false) -> trans_bool ctx (Bool false)
  | And (Bool true, b) | And (b, Bool true) -> trans_bool ctx b
  (* General case *)
  | And (b1, b2) ->
      let ctx, r1, c1 = trans_bool ctx b1 in
      let ctx, r2, c2 = trans_bool ctx b2 in
      let ctx', r = allocate_register ctx in
      (ctx', r, c1 @ c2 @ [ BinRegOp (And, r1, r2, r) ])
  (* Double negation: not (not b) = b *)
  | Not (Not b) -> trans_bool ctx b
  (* Constant folding for Not *)
  | Not (Bool b) -> trans_bool ctx (Bool (not b))
  (* General case *)
  | Not b ->
      let ctx, r1, c1 = trans_bool ctx b in
      let ctx', r = allocate_register ctx in
      (ctx', r, c1 @ [ UnaryOp (Not, r1, r) ])
  (* Less comparison *)
  | Less (op1, op2) ->
      let ctx, r1, c1 = trans_op ctx op1 in
      let ctx, r2, c2 = trans_op ctx op2 in
      let ctx', r = allocate_register ctx in
      (ctx', r, c1 @ c2 @ [ BinRegOp (Less, r1, r2, r) ])

(* ========== Command Translation ========== *)

(* Returns (ctx, commands, last_cond_register_option) *)
let rec trans_cmd ctx = function
  | Skip -> (ctx, [ Nop ], None)
  | Assign (v, op) ->
      let ctx, result_reg, cmds = trans_op ctx op in

      (* Check if this is input or output variable *)
      let target_reg, ctx' =
        if v = ctx.input_var then
          ( input_register,
            { ctx with var_to_reg = VarMap.add v input_register ctx.var_to_reg }
          )
        else if v = ctx.output_var then
          ( output_register,
            {
              ctx with
              var_to_reg = VarMap.add v output_register ctx.var_to_reg;
            }
          )
        else
          (* Check if variable already has a register *)
          match VarMap.find_opt v ctx.var_to_reg with
          | Some existing_reg -> (existing_reg, ctx)
          | None ->
              ( result_reg,
                { ctx with var_to_reg = VarMap.add v result_reg ctx.var_to_reg }
              )
      in

      (* If result is not already in target register, copy it *)
      let final_cmds =
        if target_reg = result_reg then cmds
        else cmds @ [ UnaryOp (Copy, result_reg, target_reg) ]
      in
      (ctx', final_cmds, None)
  | Seq (c1, c2) ->
      let ctx, cmds1, _ = trans_cmd ctx c1 in
      let ctx, cmds2, cond_reg = trans_cmd ctx c2 in
      (ctx, cmds1 @ cmds2, cond_reg)
  | If (cond, _, _) | While (cond, _) ->
      (* Translate condition and remember which register has the result *)
      let ctx, cond_reg, cmds = trans_bool ctx cond in
      (ctx, cmds, Some cond_reg)

(* Translate a list of commands and apply peephole optimization *)
let trans_cmd_list ctx cmds =
  let ctx, acc_cmds, cond_reg =
    List.fold_left
      (fun (ctx, acc_cmds, _) cmd ->
        let ctx, new_cmds, cond_reg = trans_cmd ctx cmd in
        (ctx, acc_cmds @ new_cmds, cond_reg)
      )
      (ctx, [], None) cmds
  in
  (* Apply peephole optimization to the generated commands *)
  (ctx, acc_cmds, cond_reg)

(* ========== CFG Translation ========== *)

open MiniImpCFG
open MiniRISCCFG

let translate_cfg ?(verbose = false) input_var output_var
    (imp_cfg : MiniImpCFG.cfg) : risc_cfg =
  log_verbose verbose "\n=== MiniImp -> MiniRISC ===";

  (* Create labels for all blocks *)
  let block_labels =
    MiniImpCFG.BlockMap.mapi (fun id _ -> make_label id) imp_cfg.blocks
  in

  let get_label id = MiniImpCFG.BlockMap.find id block_labels in

  (* Initialize context with input/output variable names *)
  let ctx =
    {
      var_to_reg = VarMap.empty;
      next_reg = 0;
      input_var;
      output_var;
      all_registers = [];
    }
  in

  let _, risc_blocks =
    MiniImpCFG.BlockMap.fold
      (fun id imp_block (ctx, acc) ->
        let label = get_label id in
        let ctx, risc_cmds, cond_reg_opt = trans_cmd_list ctx imp_block.stmts in

        (* Determine terminator from edges *)
        let successors = MiniImpCFG.get_successors imp_cfg id in
        let terminator =
          match successors with
          | [] -> None
          | [ (succ_id, Unconditional) ] -> Some (Jump (get_label succ_id))
          | [ (s1, True); (s2, False) ] | [ (s2, False); (s1, True) ] ->
              (* Use the condition register from command translation *)
              let cond_reg =
                match cond_reg_opt with
                | Some reg -> reg
                | None -> (
                    (* Fallback: recompute condition if needed *)
                    match List.rev imp_block.stmts with
                    | (If (cond, _, _) | While (cond, _)) :: _ ->
                        let _, r, _ = trans_bool ctx cond in
                        r
                    | _ -> Register "r_error"
                  )
              in
              Some (CJump (cond_reg, get_label s1, get_label s2))
          | _ -> None
        in

        let risc_block = { id; label; commands = risc_cmds; terminator } in
        (ctx, MiniRISCCFG.BlockMap.add id risc_block acc)
      )
      imp_cfg.blocks
      (ctx, MiniRISCCFG.BlockMap.empty)
  in

  (* Convert edges from MiniImpCFG to MiniRISCCFG format *)
  let risc_edges =
    MiniImpCFG.BlockMap.fold
      (fun src edge_list acc ->
        let converted_edges =
          List.map
            (fun (dst, lbl) ->
              match lbl with
              | MiniImpCFG.Unconditional -> (dst, MiniRISCCFG.Unconditional)
              | MiniImpCFG.True -> (dst, MiniRISCCFG.True)
              | MiniImpCFG.False -> (dst, MiniRISCCFG.False)
            )
            edge_list
        in
        MiniRISCCFG.BlockMap.add src converted_edges acc
      )
      imp_cfg.edges MiniRISCCFG.BlockMap.empty
  in

  let cfg =
    {
      blocks = risc_blocks;
      edges = risc_edges;
      entry = imp_cfg.entry;
      exit = imp_cfg.exit;
    }
  in

  let num_regs =
    MiniRISCCFG.BlockMap.fold
      (fun _ block acc ->
        List.fold_left
          (fun a cmd ->
            let used = get_used_registers cmd in
            let defined = get_defined_registers cmd in
            List.length used + List.length defined + a
          )
          acc
          (block.commands @ Option.to_list block.terminator)
      )
      cfg.blocks 0
  in

  if verbose then (
    log_verbose verbose "Generated %d blocks, %d operations"
      (MiniRISCCFG.BlockMap.cardinal cfg.blocks)
      num_regs;
    MiniRISCCFG.print_risc_cfg cfg
  );

  cfg

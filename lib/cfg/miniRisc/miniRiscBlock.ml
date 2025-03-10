open MiniRiscTypes
open MiniImpTypes

(** This module defines blocks for MiniRisc programs.
    A block represents a basic block in the control flow graph.
*)

module MiniRiscBlock = struct

  (** [block] represents a block in a MiniRisc program.
      It consists of:
      - a [label] identifying the block,
      - a list of [commands] that belong to the block,
      - a [term] command that acts as the block's terminator.
  *)
  type block = {
    label : label;
    commands : command list;
    term : command;
  }

  let new_label id = Label ("l" ^ string_of_int id)

  let new_register =
    let register_counter = ref 0 in
    fun () ->
      let r = !register_counter in
      incr register_counter;
      Register ("r" ^ string_of_int r)

  
  let get_register var reg_map =
    match VarMap.find_opt var reg_map with 
        | Some reg ->
            (reg, reg_map)
        | None ->
            let new_reg = new_register () in 
            let new_reg_map = VarMap.add var new_reg reg_map in  
            (new_reg, new_reg_map)

  
  let rec translate_aexpr (reg_map : register_map) = function
    | Num n -> 
        let new_reg = new_register () in 
        ([LoadI (n, new_reg)], new_reg, reg_map)
    | Var v -> 
        let var_register, reg_map = get_register v reg_map in
        ([], var_register, reg_map)
    | Plus (a1, a2) ->
        match a1, a2 with 
        | _, Num n ->
            let code, r1, reg_map = translate_aexpr reg_map a1 in
            let tmp = new_register () in
            ([BinImmOp(AddI, r1, n, tmp)] :: code, tmp, reg_map) 
        | Num n, _ ->
            let code, r2, reg_map = translate_aexpr reg_map a2 in
            let tmp = new_register () in
            ([BinImmOp(AddI, r2, n, tmp)] :: code, tmp, reg_map)
        | _ ->
          let code1, r1, reg_map = translate_aexpr reg_map a1 in
          let code2, r2, reg_map = translate_aexpr reg_map a2 in
          let tmp = new_register () in 
          ([BinRegOp(Add, r1, r2, temp)] :: code2 :: code1, tmp, reg_map)
    | Minus (a1, a2) -> failwith "aaa"
    | Times (a1, a2) -> failwith "bbbb"

    and translate_binop ~commutative ~brop ~biop a1 a2 reg_map =
      if commutative then
          match a1, a2 with
          | _, Num n -> 
              let code, r1, reg_map = translate_aexpr reg_map a1 in
              let tmp = new_register () in
              (BinImmOp(biop, r1, n, tmp) :: code, tmp, reg_map)
          | Num n, _ ->
              let code, r2, reg_map = translate_aexpr reg_map a2 in
              let tmp = new_register () in
              (BinImmOp(biop, r2, n, tmp) :: code, tmp, reg_map)
          | _ ->
            let code1, r1, reg_map = translate_aexpr reg_map a1 in
            let code2, r2, reg_map = translate_aexpr reg_map a2 in
            let tmp = new_register () in 
            (BinRegOp(brop, r1, r2, tmp) :: code2 :: code1, tmp, reg_map)
      else
          match a2 with 
          | Num n ->
            let code, r1, reg_map = translate_aexpr reg_map a1 in
            let tmp = new_register () in
            (BinImmOp(biop, r1, n, tmp) :: code, tmp, reg_map)
          | _ ->
            let code1, r1, reg_map = translate_aexpr reg_map a1 in
            let code2, r2, reg_map = translate_aexpr reg_map a2 in
            let tmp = new_register () in 
            (BinRegOp(brop, r1, r2, tmp) :: code2 :: code1, tmp, reg_map)


        
end
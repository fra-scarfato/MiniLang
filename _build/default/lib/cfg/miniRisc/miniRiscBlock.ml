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

  (* let rec translate_aexpr (reg_map : register_map) = function
    | Num n -> 
        let new_reg = new_register () in 
        ([LoadI (n, new_reg)], new_reg, reg_map)
    | Var v -> 
        match VarMap.find_opt v reg_map with 
        | Some reg ->
            ([], Register(reg), reg_map)
        | None ->
            let new_reg = new_register () in 
            let new_reg_map = VarMap.add v new_reg reg_map in 
            ([], new_reg, new_reg_map) *)
        
end
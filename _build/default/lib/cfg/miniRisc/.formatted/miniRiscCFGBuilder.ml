(* open MiniImpCFG open MiniRisc open MiniRiscUtils open MiniImpTypes

   let rec translate_arith_expr = function | Num n -> let r = new_register () in
   ([LoadI (n, r)], r) | Var v -> match Map.find_opt v !reg_map with | Some reg
   -> Register (reg) | None -> let v_reg = new_register () in reg_map := Map.add
   v v_reg !reg_map in let r = new_register () in ([Load (v_reg, r)], r) *)

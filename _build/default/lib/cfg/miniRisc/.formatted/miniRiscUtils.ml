open MiniRisc

let reg_map = ref Map.empty
let new_label id = Label ("l" ^ string_of_int id)

let new_register =
  let register_counter = ref 0 in
  fun () ->
    let r = !register_counter in
    incr register_counter;
    Register ("r" ^ string_of_int r)

let string_of_register (Register r) = r

let get_register_of_var var =
  match Map.find_opt var !reg_map with
  | Some reg -> Register reg
  | None ->
      let var_reg = new_register () in
      reg_map := Map.add var (string_of_register var_reg) !reg_map;
      var_reg

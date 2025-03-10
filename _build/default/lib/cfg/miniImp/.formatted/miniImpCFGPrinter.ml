open MiniImpCFG
open MiniImpTypes

let rec string_of_aexpr = function
  | Num n -> string_of_int n
  | Var x -> x
  | Plus (a1, a2) ->
      Printf.sprintf "(%s + %s)" (string_of_aexpr a1) (string_of_aexpr a2)
  | Minus (a1, a2) ->
      Printf.sprintf "(%s - %s)" (string_of_aexpr a1) (string_of_aexpr a2)
  | Times (a1, a2) ->
      Printf.sprintf "(%s * %s)" (string_of_aexpr a1) (string_of_aexpr a2)

let rec string_of_bexpr = function
  | Bool b -> string_of_bool b
  | And (b1, b2) ->
      Printf.sprintf "(%s && %s)" (string_of_bexpr b1) (string_of_bexpr b2)
  | Not b -> Printf.sprintf "!(%s)" (string_of_bexpr b)
  | Less (a1, a2) ->
      Printf.sprintf "(%s < %s)" (string_of_aexpr a1) (string_of_aexpr a2)

let rec string_of_command = function
  | Skip -> "skip"
  | Assign (var, expr) -> Printf.sprintf "%s := %s" var (string_of_aexpr expr)
  | Seq (c1, c2) ->
      Printf.sprintf "%s;\n%s" (string_of_command c1) (string_of_command c2)
  | If (cond, _, _) -> Printf.sprintf "if %s" (string_of_bexpr cond)
  | While (cond, _) -> Printf.sprintf "while %s do\n" (string_of_bexpr cond)

(* Helper function to convert a terminator to a string *)
let string_of_terminator (term : terminator) : string =
  match term with
  | Jump target -> Printf.sprintf "    jump -> Block %d" target
  | CondJump (t, f) ->
      Printf.sprintf "    true → Block %d\n    false → Block %d" t f
  | End -> "    exit"

(* Convert a block to a string *)
let string_of_block (block_id : int) (block : block) : string =
  let commands_str =
    block.commands |> List.map string_of_command
    |> List.map (fun s -> "    " ^ s) (* Indent commands *)
    |> String.concat "\n"
  in
  let terminator_str = string_of_terminator block.term in
  Printf.sprintf "Block %d:\n  Commands:\n%s\n  Terminator:\n%s\n" block_id
    commands_str terminator_str

(* Convert the entire CFG to a string *)
let string_of_cfg (cfg : cfg) : string =
  KeyMap.fold
    (fun block_id block acc -> acc ^ string_of_block block_id block ^ "\n")
    cfg.nodes ""

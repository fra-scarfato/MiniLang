open MiniImpSyntax

(* Lookup variable in memory *)
let find (var : string) (mem : memory) : int =
  match StringMap.find_opt var mem with
  | Some v -> v
  | None -> failwith ("Undefined variable: " ^ var)

(* Set variable in memory *)
let set (var : string) (x : int) (mem : memory) : memory =
  StringMap.add var x mem

(* Evaluate arithmetic expressions *)
let rec eval_op (mem : memory) = function
  | Constant n -> n
  | Variable var -> find var mem
  | Plus (a1, a2) -> eval_op mem a1 + eval_op mem a2
  | Minus (a1, a2) -> eval_op mem a1 - eval_op mem a2
  | Times (a1, a2) -> eval_op mem a1 * eval_op mem a2

(* Evaluate boolean expressions *)
let rec eval_bool (mem : memory) = function
  | Bool b -> b
  | And (b1, b2) -> eval_bool mem b1 && eval_bool mem b2
  | Not b -> not (eval_bool mem b)
  | Less (a1, a2) -> eval_op mem a1 < eval_op mem a2

(* Evaluate commands *)
let rec eval_command (mem : memory) = function
  | Skip -> mem
  | Assign (var, a) -> set var (eval_op mem a) mem
  | Seq (c1, c2) ->
      let mem' = eval_command mem c1 in
      eval_command mem' c2
  | If (b, c1, c2) ->
      if eval_bool mem b then eval_command mem c1 else eval_command mem c2
  | While (b, c) ->
      if eval_bool mem b then eval_command (eval_command mem c) (While (b, c))
      else mem

(* Run a program *)
let eval_program (n : int) = function
  | Prog (input_var, output_var, body) ->
      let mem = set input_var n StringMap.empty in
      find output_var (eval_command mem body)

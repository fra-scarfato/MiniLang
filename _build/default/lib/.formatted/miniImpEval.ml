open MiniImpTypes

(*---- Evaluation Functions ----*)

(* The 'eval_arith' function evaluates an arithmetic expression (arith_expr)
   given the current memory. *)
let rec eval_arith (mem : memory) = function
  | Num n -> n (* Return the constant integer value *)
  | Var var -> (
      match MemoryMap.find_opt var mem with
      | Some v -> v (* Look up the variable value in the memory *)
      | None ->
          failwith ("Undefined variable " ^ var)
          (* Fail if the variable is not found in memory *)
    )
  | Plus (a1, a2) ->
      eval_arith mem a1
      + eval_arith mem a2 (* Evaluate the sum of two expressions *)
  | Minus (a1, a2) ->
      eval_arith mem a1
      - eval_arith mem a2 (* Evaluate the difference of two expressions *)
  | Times (a1, a2) ->
      eval_arith mem a1
      * eval_arith mem a2 (* Evaluate the product of two expressions *)

(* The 'eval_bool' function evaluates a boolean expression (bool_expr) given the
   current memory. *)
let rec eval_bool (mem : memory) = function
  | Bool b -> b (* Return the constant boolean value *)
  | And (b1, b2) ->
      eval_bool mem b1
      && eval_bool mem b2 (* Logical AND of two boolean expressions *)
  | Not b -> not (eval_bool mem b) (* Logical NOT of a boolean expression *)
  | Less (a1, a2) ->
      eval_arith mem a1
      < eval_arith mem a2 (* Compare two arithmetic expressions (a1 < a2) *)

(* The 'eval_command' function evaluates a command (command) given the current
   memory. It handles all possible command types and recursively evaluates
   subcommands. *)
let rec eval_command (mem : memory) = function
  | Skip -> mem (* No-op, return the current memory unchanged *)
  | Assign (var, a) ->
      let x = eval_arith mem a in
      (* Evaluate the arithmetic expression for the assignment *)
      MemoryMap.add var x mem (* Add the variable and its value to the memory *)
  | Seq (c1, c2) ->
      let mem_c1 = eval_command mem c1 in
      (* Evaluate the first command *)
      eval_command mem_c1
        c2 (* Evaluate the second command with the updated memory *)
  | If (b, c1, c2) ->
      eval_command mem
        ( match eval_bool mem b with
        (* Evaluate the boolean expression for the condition *)
        | true -> c1 (* If true, execute the first command *)
        | false -> c2
        )
      (* If false, execute the second command *)
  | While (b, c) -> (
      match eval_bool mem b with
      (* Evaluate the boolean expression for the condition *)
      | true ->
          let mem' = eval_command mem c in
          (* Execute the command if the condition is true *)
          eval_command mem' (While (b, c))
          (* Recursively evaluate the while loop with the updated memory *)
      | false ->
          mem
          (* If the condition is false, stop the loop and return the current
             memory *)
    )

(* The 'eval_program' function initializes the memory with the input variable
   and its value (n), then evaluates the program's body, and finally retrieves
   the value of the output variable. *)
let eval_program (n : int) = function
  | Prog (input_var, output_var, body) -> (
      (* Initialize memory with the input variable set to the given value (n) *)
      let mem = MemoryMap.add input_var n MemoryMap.empty in
      let final_mem = eval_command mem body in
      (* Evaluate the program body to update memory *)
      (* Retrieve the value of the output variable *)
      match MemoryMap.find_opt output_var final_mem with
      | Some result ->
          result (* Return the value of the output variable if found *)
      | None -> failwith ("Output variable " ^ output_var ^ " not found")
    )

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

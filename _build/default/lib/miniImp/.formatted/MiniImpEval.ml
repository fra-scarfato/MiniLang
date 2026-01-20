open MiniImpTypes

let find (var : string) (mem : memory) =
  match Hashtbl.find_opt mem var with
  | Some v -> v (* Look up the variable value in the memory *)
  | None -> failwith ("Undefined variable " ^ var)
(* Fail if the variable is not found in memory *)

let set (var : string) (x : int) (mem : memory) =
  Hashtbl.add mem var x;
  mem (* Add the variable and its value to the memory *)

(*---- Evaluation Functions ----*)

(* The 'eval_op' function evaluates an arithmetic expression (arith_expr) given
   the current memory. *)
let rec eval_op (mem : memory) = function
  | Constant n -> n (* Return the constant integer value *)
  | Variable var -> find var mem
  | Plus (a1, a2) ->
      eval_op mem a1 + eval_op mem a2 (* Evaluate the sum of two expressions *)
  | Minus (a1, a2) ->
      eval_op mem a1
      - eval_op mem a2 (* Evaluate the difference of two expressions *)
  | Times (a1, a2) ->
      eval_op mem a1
      * eval_op mem a2 (* Evaluate the product of two expressions *)

(* The 'eval_bool' function evaluates a boolean expression (bool_expr) given the
   current memory. *)
let rec eval_bool (mem : memory) = function
  | Bool b -> b (* Return the constant boolean value *)
  | And (b1, b2) ->
      eval_bool mem b1
      && eval_bool mem b2 (* Logical AND of two boolean expressions *)
  | Not b -> not (eval_bool mem b) (* Logical NOT of a boolean expression *)
  | Less (a1, a2) ->
      eval_op mem a1
      < eval_op mem a2 (* Compare two arithmetic expressions (a1 < a2) *)

(* The 'eval_command' function evaluates a command (command) given the current
   memory. It handles all possible command types and recursively evaluates
   subcommands. *)
let rec eval_command (mem : memory) = function
  | Skip -> mem (* No-op, return the current memory unchanged *)
  | Assign (var, a) ->
      set var (eval_op mem a)
        mem (* Add the variable and its EVALUATED value to the memory *)
  | Seq (c1, c2) ->
      eval_command (eval_command mem c1)
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
          eval_command (eval_command mem c) (While (b, c))
          (* Recursively evaluate the while loop with the updated memory *)
      | false -> mem
    )
(* If the condition is false, stop the loop and return the current memory *)

(* The 'eval_program' function initializes the memory with the input variable
   and its value (n), then evaluates the program's body, and finally retrieves
   the value of the output variable. *)
let eval_program (n : int) = function
  | Prog (input_var, output_var, body) ->
      (* Initialize memory with the input variable set to the given value (n) *)
      let mem = Hashtbl.create 16 in
      Hashtbl.add mem input_var n;
      (* Evaluate the program and retrieve the output*)
      find output_var (eval_command mem body)

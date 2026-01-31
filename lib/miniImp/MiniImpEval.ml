open MiniImpSyntax

(* =============================================================================
 * MINIIMP INTERPRETER: Direct Execution
 * =============================================================================
 *
 * This module implements a straightforward interpreter for MiniImp programs.
 * It executes code DIRECTLY without any compilation - just recursive
 * evaluation following the AST structure.
 *
 * THE EVALUATION STRATEGY: ENVIRONMENT-PASSING
 * ---------------------------------------------
 * We use a functional map (memory) to store variable values. Each evaluation
 * function takes the current memory and returns:
 *   - For expressions: The computed value
 *   - For commands: The updated memory
 *
 * This is PURE FUNCTIONAL: no mutable state, no side effects. The memory
 * is threaded through the computation, with each step producing a NEW
 * memory that might differ from the old one.
 *
 * Example:
 *   mem1 = {x -> 5}
 *   Evaluate: x = x + 1
 *   mem2 = {x -> 6}  (NEW map, mem1 unchanged)
 *
 * HANDLING UNDEFINED VARIABLES:
 * -----------------------------
 * Unlike languages with NULL or undefined values, we FAIL HARD if you try
 * to read an undefined variable. This is intentional:
 *
 *   - Catches programmer errors early
 *   - Makes semantics simpler (no need to track "undefined" state)
 *   - Matches the behavior of statically-typed languages
 *
 * THE WHILE LOOP STRATEGY:
 * ------------------------
 * Look carefully at eval_command for While. It's RECURSIVE:
 *
 *   While(b, c) evaluates to:
 *     if b is true:  eval c, then recursively eval While(b, c) again
 *     if b is false: return current memory
 *
 * This is elegant but inefficient (could blow the stack on long loops).
 *)

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

(* -----------------------------------------------------------------------------
 * eval_bool: Evaluate Boolean Expressions
 * -----------------------------------------------------------------------------
 *
 * Recursively evaluates a boolean expression in the current memory environment.
 * Returns a boolean value (true/false).
 *
 * EXAMPLE:
 *   eval_bool {x -> 5} (Less(Variable "x", Constant 10))  ==>  true
 *)
let rec eval_bool (mem : memory) = function
  | Bool b -> b
  | And (b1, b2) -> eval_bool mem b1 && eval_bool mem b2
  | Not b -> not (eval_bool mem b)
  | Less (a1, a2) -> eval_op mem a1 < eval_op mem a2

(* -----------------------------------------------------------------------------
 * eval_command: Execute Commands and Update Memory
 * -----------------------------------------------------------------------------
 *
 * Executes a command, potentially modifying the memory environment.
 * Returns the updated memory.
 *
 * KEY BEHAVIORS:
 * - Skip: Returns memory unchanged
 * - Assign: Updates one variable
 * - Seq: Threads memory through two commands (do first, then second)
 * - If: Branches based on condition evaluation
 * - While: Recursively re-executes until condition becomes false
 *
 * PURE FUNCTIONAL: No side effects, returns new memory instead of mutating.
 *)
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

(* -----------------------------------------------------------------------------
 * eval_program: Main Entry Point for Program Execution
 * -----------------------------------------------------------------------------
 *
 * Executes a complete MiniImp program with the given input value.
 *
 * CALLING CONVENTION:
 * - Takes integer input n
 * - Initializes memory with input_var = n
 * - Executes the program body
 * - Returns the value of output_var
 *
 * EXAMPLE:
 *   program: def main with input x output y as y := x + 1
 *   eval_program 5 program  ==>  6
 *)
let eval_program (n : int) = function
  | Prog (input_var, output_var, body) ->
      let mem = set input_var n StringMap.empty in
      find output_var (eval_command mem body)

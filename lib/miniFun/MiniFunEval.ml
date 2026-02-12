(* =============================================================================
 * MINIFUN INTERPRETER: ENVIRONMENT-BASED EVALUATION OF FUNCTIONAL PROGRAMS
 * =============================================================================
 *
 * This module implements the runtime semantics of MiniFun - how programs
 * actually execute. We use an ENVIRONMENT-BASED evaluation strategy, which
 * is more efficient and realistic than the substitution-based approach often
 * taught in theoretical courses.
 *
 * THE EVALUATION STRATEGY:
 * ------------------------
 * Rather than replacing variables with their values in the syntax tree
 * (substitution), we maintain an ENVIRONMENT - a mapping from variable names
 * to runtime values. When we encounter a variable, we look it up in the
 * environment. When we bind a variable (let, function parameter), we extend
 * the environment.
 *
 * WHY ENVIRONMENT-BASED?
 * ----------------------
 * 1. EFFICIENCY: No need to copy and modify syntax trees
 * 2. CLOSURES: Naturally represents captured environments
 * 3. REALISTIC: This is how real interpreters and compilers work
 * 4. SHARING: Multiple closures can share the same environment structure
 *
 * CLOSURE SEMANTICS:
 * ------------------
 * When evaluating a function definition (Fun or LetFun), we create a closure
 * that captures the CURRENT environment. This is lexical scoping - the
 * function remembers where it was defined, not where it's called.
 *
 * When applying a function:
 * 1. Evaluate the function expression -> should get a Closure
 * 2. Evaluate the argument expression -> get a value
 * 3. Extend the closure's environment with the parameter binding
 * 4. For recursive functions, also bind the function name to itself
 * 5. Evaluate the body in this extended environment
 *
 * RECURSION: THE ENVIRONMENT TRICK
 * ---------------------------------
 * Recursive functions are tricky because the function needs to call itself,
 * but how can it reference itself before it's fully defined?
 *
 * Solution: When creating a recursive closure, we later bind the function
 * name to the closure IN THE CLOSURE'S OWN ENVIRONMENT. When the function
 * body evaluates and encounters the function name, it finds itself in the
 * environment and can recurse.
 *
 * EXAMPLE:
 *   letfun factorial n =
 *     if n < 2 then 1
 *     else n * factorial (n - 1)
 *   in factorial 5
 *
 * 1. Create closure: ClosureRec("factorial", "n", body, {})
 * 2. Bind "factorial" -> closure in environment: {factorial -> closure}
 * 3. Evaluate body: when we see "factorial" in the recursive call, we look
 *    it up and find the closure, allowing recursion to work.
 *)

open MiniFunSyntax


let eval_bin_op (operator : binary_op) (op1 : value) (op2 : value) =
  match (operator, op1, op2) with
  | Plus, Int op1, Int op2 -> Int (op1 + op2)
  | Minus, Int op1, Int op2 -> Int (op1 - op2)
  | Times, Int op1, Int op2 -> Int (op1 * op2)
  | Less, Int op1, Int op2 -> Bool (op1 < op2)
  | And, Bool op1, Bool op2 -> Bool (op1 && op2)
  | _ -> failwith "Invalid operation for the operands"


let eval_unary_op (operator : unary_op) (op : value) =
  match (operator, op) with
  | Not, Bool op -> Bool (not op)
  | _ -> failwith "Invalid operation for the operands"


let rec eval (env : environment) = function
  | IntLit n -> Int n
  | BoolLit b -> Bool b
  | Var x -> (
      try EnvMap.find x env
      with Not_found -> failwith ("Undefined variable " ^ x)
    )
  | BinOp (t1, operator, t2) ->
      (* Evaluate both operands first (eager evaluation), then apply operator *)
      let op1 = eval env t1 in
      let op2 = eval env t2 in
      eval_bin_op operator op1 op2
  | UnaryOp (operator, t) ->
      (* Evaluate operand, then apply operator *)
      let op = eval env t in
      eval_unary_op operator op
  | If (t1, t2, t3) -> (
      (* Evaluate condition first *)
      let condition = eval env t1 in
      match condition with
      | Bool true -> eval env t2   (* Then branch *)
      | Bool false -> eval env t3  (* Else branch *)
      | _ -> failwith "Expected a boolean condition"
    )
  | Fun (x, t) -> 
      (* Create a closure that packages: the parameter name (x), the body (t)
       * and the current environment (env).
       * The body will be evaluated later when the function is applied to an argument.
       *)
      Closure (ClosureNoRec (x, t, env))
  | FunApp (t1, t2) -> (
      (* Evaluate the function expression first *)
      let value_fun = eval env t1 in
      match value_fun with
      | Closure (ClosureNoRec (x, t, env')) ->
          (* Non-recursive function application *)
          (* Evaluate argument and bind to parameter in closure's environment *)
          eval (EnvMap.add x (eval env t2) env') t
      | Closure (ClosureRec (f, x, t, env')) ->
          (* Recursive function application *)
          (* First bind the function name to itself (for recursion) *)
          let env_rec_f = EnvMap.add f value_fun env' in
          (* Then bind the argument to the parameter *)
          let final_env = EnvMap.add x (eval env t2) env_rec_f in
          (* Evaluate body with both bindings *)
          eval final_env t
      | _ -> failwith "Expected a function"
    )
  | Let (x, t1, t2) ->
      let value_arg = eval env t1 in
      eval (EnvMap.add x value_arg env) t2
  | LetFun (f, x, t1, t2) ->
      (* Create a ClosureRec that will later bind its own name (f) in its
       * environment when applied. This allows the body to reference f.*)
      let value_fun = Closure (ClosureRec (f, x, t1, env)) in
      eval (EnvMap.add f value_fun env) t2

(* -----------------------------------------------------------------------------
 * eval_program: Entry point for program evaluation
 * -----------------------------------------------------------------------------
 *
 * MiniFun programs are typically functions that take an input integer.
 * This wrapper tries to apply the program to the input value.
 *
 * If the program is not a function (e.g., just "42" or "let x = 5 in x + 3"),
 * we evaluate it directly and warn that the input wasn't used.
 *
 * EXAMPLE:
 *   Program: fun x -> x * 2
 *   Input: 5
 *   Result: eval_program 5 (Fun("x", BinOp(...))) => Int 10
 *)
let eval_program (input_int : int) (t : term) = 
  (* Try to apply t to input; if t is not a function, just evaluate it *)
  try eval EnvMap.empty (FunApp (t, IntLit input_int))
  with Failure _ -> 
    Printf.printf "Warning: The program is not a function, input %d is not being used.\n" input_int;
    eval EnvMap.empty t

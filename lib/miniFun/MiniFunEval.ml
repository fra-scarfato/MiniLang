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
      let op1 = eval env t1 in
      let op2 = eval env t2 in
      eval_bin_op operator op1 op2
  | UnaryOp (operator, t) ->
      let op = eval env t in
      eval_unary_op operator op
  | If (t1, t2, t3) -> (
      let condition = eval env t1 in
      match condition with
      | Bool true -> eval env t2
      | Bool false -> eval env t3
      | _ -> failwith "Expected a boolean condition"
    )
  (* Definition of non recursive function *)
  | Fun (x, t) -> Closure (ClosureNoRec (x, t, env))
  (* Application of function t1 to the argument t2 *)
  | FunApp (t1, t2) -> (
      (* 1. Evaluate the first argument 2. Check if it is a closure 3. If it is
         a closure, evaluate the argument t2 4. Apply the function to the
         argument *)
      let value_fun = eval env t1 in
      match value_fun with
      | Closure (ClosureNoRec (x, t, env')) ->
          (* Bind argument and evaluate the body of non recursive function *)
          eval (EnvMap.add x (eval env t2) env') t
      | Closure (ClosureRec (f, x, t, env')) ->
          (* Bind the value of the function *)
          let env_rec_f = EnvMap.add f value_fun env' in
          (* Bind the value of the argument *)
          let final_env = EnvMap.add x (eval env t2) env_rec_f in
          (* Evaluate the body of the function *)
          eval final_env t
      | _ -> failwith "Expected a function"
    )
  | Let (x, t1, t2) ->
      (* 1. Evaluate the term t1 2. Bind the result to the variable x in the
         environment 3. Evaluate the body t2 in the extended environment *)
      let value_arg = eval env t1 in
      eval (EnvMap.add x value_arg env) t2
  | LetFun (f, x, t1, t2) ->
      let value_fun = Closure (ClosureRec (f, x, t1, env)) in
      eval (EnvMap.add f value_fun env) t2

let eval_program (t : term) = eval EnvMap.empty t

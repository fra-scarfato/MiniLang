open MiniTyFunSyntax

let type_check_bin_op (operator : binary_op) (op1 : typ) (op2 : typ) =
  match (operator, op1, op2) with
  (* Type check that Plus, Minus, and Times are used with Int and return Int *)
  | (Plus | Minus | Times), Int, Int -> Int
  (* Type check that Less is used with Int and return Bool *)
  | Less, Int, Int -> Bool
  (* Type check that And is used with Bool and return Bool *)
  | And, Bool, Bool -> Bool
  | _ -> failwith "Invalid operation for the operands"

let type_check_unary_op (operator : unary_op) (op : typ) =
  match (operator, op) with
  (* Type check that Not is used with Bool and return Bool *)
  | Not, Bool -> Bool
  | _ -> failwith "Invalid operation for the operands"

let rec type_check (env : environment) = function
  | IntLit _ -> Int
  | BoolLit _ -> Bool
  | Var x -> (
      try EnvMap.find x env
      with Not_found -> failwith ("Undefined variable " ^ x)
    )
  | BinOp (t1, operator, t2) ->
      let op1 = type_check env t1 in
      let op2 = type_check env t2 in
      type_check_bin_op operator op1 op2
  | UnaryOp (operator, t) ->
      let op = type_check env t in
      type_check_unary_op operator op
  | If (t1, t2, t3) -> (
      (* Type check that the condition is Bool and both branches have the same type *)
      match (type_check env t1, type_check env t2, type_check env t3) with
      | (Bool, if_true, if_false) -> (
          match if_true == if_false with
          | true -> if_true
          | false -> failwith "Branches of the if must return the same type"
        )
      | _ -> failwith "Condition of the if must be a boolean"
    )
  | Fun (x, x_type, t) -> 
    Closure (x_type, type_check (EnvMap.add x x_type env) t)
    
  | FunApp (t1, t2) -> (
      (* Type check that the function is a Closure and the argument matches the input type *)
      match type_check env t1, type_check env t2 with
      | Closure(in_type, out_type), arg_type -> (
          match in_type == arg_type with
          | true -> out_type
          | false -> failwith "Function argument type does not match"
        )
      | _ -> failwith "Expected a function in the application"
    )
  | Let (x, t1, t2) -> type_check (EnvMap.add x (type_check env t1) env) t2 
  | LetFun (f, x, f_type, t1, t2) -> (
      (* Type check that the function has a function type and the same return type of t2 *)
      match f_type with
      | Closure (in_type, out_type) -> (
          let body_type = type_check (EnvMap.add x in_type (EnvMap.add f f_type env)) t1 in
          match body_type == out_type with
          | true -> type_check (EnvMap.add f f_type env) t2
          | false -> failwith "Function body type does not match the declared return type"
        )
      | _ -> failwith "LetFun requires a function type"
  )

  (* Return Some type if the program is well-typed, None otherwise *)
  let type_check_program term = 
    try Some (type_check EnvMap.empty term) with _ -> None
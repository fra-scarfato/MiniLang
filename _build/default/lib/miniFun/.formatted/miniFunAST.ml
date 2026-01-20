module EnvMap = Map.Make (String)

type binary_op = Plus | Minus | Times | Less | And [@@deriving show]
type unary_op = Not [@@deriving show]

(* Value that can be defined in the environment *)
type value = Int of int | VBool of bool | Closure of closure [@@deriving show]

(* Closure represents the non-recursive function and the recursive ones *)
and closure =
  | ClosureNoRec of string * term * environment
  | ClosureRec of string * string * term * environment
[@@deriving show]

(* environment is a map key-value in which the values are of type "value" *)
and environment = value EnvMap.t

and term =
  | Num of int
  | Bool of bool
  | Var of string
  | Fun of string * term
  | FunApp of term * term
  | BinOp of term * binary_op * term
  | UnaryOp of unary_op * term
  | If of term * term * term
  | Let of string * term * term
  | LetFun of string * string * term * term
[@@deriving show]

let eval_bin_op (operator : binary_op) (op1 : value) (op2 : value) =
  match (operator, op1, op2) with
  | Plus, Int op1, Int op2 -> Int (op1 + op2)
  | Minus, Int op1, Int op2 -> Int (op1 - op2)
  | Times, Int op1, Int op2 -> Int (op1 * op2)
  | Less, Int op1, Int op2 -> VBool (op1 < op2)
  | And, VBool op1, VBool op2 -> VBool (op1 && op2)
  | _ -> failwith "Invalid operation for the operands"

let eval_unary_op (operator : unary_op) (op : value) =
  match (operator, op) with
  | Not, VBool op -> VBool (not op)
  | _ -> failwith "Invalid operation for the operands"

let rec eval (env : environment) = function
  | Num n -> Int n
  | Bool b -> VBool b
  | Var x -> (
      try EnvMap.find x env
      with Not_found -> failwith ("Undefined variable " ^ x)
    )
  (* Definition of non recursive function *)
  | Fun (x, t) -> Closure (ClosureNoRec (x, t, env))
  (* Application of function t1 to the argument t2 *)
  | FunApp (t1, t2) -> (
      (* Evaluate function *)
      let value_fun = eval env t1 in
      (* Evaluate argument *)
      let value_arg = eval env t2 in
      match value_fun with
      | Closure (ClosureNoRec (x, t, env')) ->
          (* Bind argument and evaluate the body of non recursive function *)
          eval (EnvMap.add x value_arg env') t
      | Closure (ClosureRec (f, x, t, env')) ->
          (* Bind the value of the function *)
          let env_rec_f = EnvMap.add f value_fun env' in
          (* Bind the value of the argument *)
          let final_env = EnvMap.add x value_arg env_rec_f in
          (* Evaluate the body of the function *)
          eval final_env t
      | _ -> failwith "Expected a function"
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
      | VBool true -> eval env t2
      | VBool false -> eval env t3
      | _ -> failwith "Expected a boolean condition"
    )
  | Let (x, t1, t2) ->
      let value_arg = eval env t1 in
      (* Bind the evaluated argument and evaluate the body *)
      eval (EnvMap.add x value_arg env) t2
  | LetFun (f, x, t1, t2) ->
      let value_fun = Closure (ClosureRec (f, x, t1, env)) in
      (* Bind the evaluated function and evaluate the body*)
      eval (EnvMap.add f value_fun env) t2

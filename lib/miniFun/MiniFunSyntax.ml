module EnvMap = Map.Make (String)

(* Binary operators: Arithmetic, comparison, and boolean *)
type binary_op = Plus | Minus | Times | Less | And [@@deriving show]

(* Unary operators: Currently only boolean negation *)
type unary_op = Not [@@deriving show]

and term =
  | IntLit of int                           (* Integer literal: 42 *)
  | BoolLit of bool                         (* Boolean literal: true, false *)
  | Var of string                           (* Variable reference: x, y *)
  | Fun of string * term                    (* Anonymous function: fun x -> body *)
  | FunApp of term * term                   (* Function application: f arg *)
  | BinOp of term * binary_op * term        (* Binary operation: a + b *)
  | UnaryOp of unary_op * term              (* Unary operation: not b *)
  | If of term * term * term                (* Conditional: if c then t else e *)
  | Let of string * term * term             (* Local binding: let x = e in body *)
  | LetFun of string * string * term * term (* Recursive function: letfun f x = body in scope *)
[@@deriving show]

type environment = value EnvMap.t

and value = Int of int | Bool of bool | Closure of closure

and closure =
  (* Non-recursive function: parameter, body, environment *)
  | ClosureNoRec of string * term * environment 
  (* Recursive function: function name, parameter, body, environment *)
  | ClosureRec of string * string * term * environment 

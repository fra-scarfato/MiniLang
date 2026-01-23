module EnvMap = Map.Make (String)

type binary_op = Plus | Minus | Times | Less | And [@@deriving show]

type unary_op = Not [@@deriving show]

and term =
  | IntLit of int
  | BoolLit of bool
  | Var of string
  | Fun of string * term
  | FunApp of term * term
  | BinOp of term * binary_op * term
  | UnaryOp of unary_op * term
  | If of term * term * term
  | Let of string * term * term
  | LetFun of string * string * term * term
[@@deriving show]

(* environment is a map key-value in which the values are of type "value" *)
type environment = value EnvMap.t

(* Value that can be defined in the environment *)
and value = Int of int | Bool of bool | Closure of closure

(* Closure represents the non-recursive function and the recursive ones *)
and closure =
  | ClosureNoRec of string * term * environment (* fun x => t*)
  | ClosureRec of string * string * term * environment (* letfun f x => t *)

module EnvMap = Map.Make (String)

type binary_op = Plus | Minus | Times | Less | And [@@deriving show]
type unary_op = Not [@@deriving show]

(* environment is a map key-value in which the values are of type "typ" *)
type environment = typ EnvMap.t

(* Value that can be defined in the environment *)
and typ = Int | Bool | Closure of typ * typ

and term =
  | IntLit of int
  | BoolLit of bool
  | Var of string
  | Fun of string * typ * term
  | FunApp of term * term
  | BinOp of term * binary_op * term
  | UnaryOp of unary_op * term
  | If of term * term * term
  | Let of string * term * term
  | LetFun of string * string * typ * term * term

module EnvMap = Map.Make (String)

(* Binary operators: same as MiniFun *)
type binary_op = Plus | Minus | Times | Less | And [@@deriving show]

(* Unary operators: same as MiniFun *)
type unary_op = Not [@@deriving show]

type environment = typ EnvMap.t

and typ = Int | Bool | Closure of typ * typ

(* Almost identical to MiniFun, with two key differences:
 *
 * 1. Fun(x, x_type, body): Function parameter has explicit type annotation
 *    - "fun (x : Int) -> x + 1"
 *    - The type annotation (x_type) is part of the syntax
 *
 * 2. LetFun(f, x, f_type, body, scope): Recursive function has explicit type
 *    - "letfun f (x : Int -> Int) = ... in ..."
 *    - The full function type (f_type) must be declared
 *)
and term =
  | IntLit of int                                      (* Integer literal: 42 *)
  | BoolLit of bool                                    (* Boolean literal: true *)
  | Var of string                                      (* Variable reference: x *)
  | Fun of string * typ * term                         (* Function with typed parameter *)
  | FunApp of term * term                              (* Function application: f arg *)
  | BinOp of term * binary_op * term                   (* Binary operation: a + b *)
  | UnaryOp of unary_op * term                         (* Unary operation: not b *)
  | If of term * term * term                           (* Conditional: if c then t else e *)
  | Let of string * term * term                        (* Local binding: let x = e in body *)
  | LetFun of string * string * typ * term * term      (* Recursive function with type *)

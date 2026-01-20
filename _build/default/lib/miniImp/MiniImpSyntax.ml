module StringMap = Map.Make(String)

(* Memory: functional map from variable names to integer values *)
type memory = int StringMap.t

(* Arithmetic expressions *)
type operation =
  | Constant of int
  | Variable of string
  | Plus of operation * operation
  | Minus of operation * operation
  | Times of operation * operation
[@@deriving show]

(* Boolean expressions *)
type boolean =
  | Bool of bool
  | And of boolean * boolean
  | Not of boolean
  | Less of operation * operation
[@@deriving show]

(* Commands *)
type command =
  | Skip
  | Assign of string * operation
  | Seq of command * command
  | If of boolean * command * command
  | While of boolean * command
[@@deriving show]

(* Program *)
type program = Prog of string * string * command [@@deriving show]
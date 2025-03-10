(* Memory is represented as a map (key-value pair) where keys are strings
   (variable names) and values are integers (the variable values). This is
   chosen because map lookups are O(1) in average time complexity, which allows
   for efficient access to variables. *)
module MemoryMap = Map.Make (String)

(* The 'memory' type is a map from string to integer, representing the state of
   variables. *)
type memory = int MemoryMap.t

(*---- Arithmetic Expression Type ----*)
(* The type 'arith_expr' defines arithmetic expressions. *)
type arith_expr =
  | Num of int (* A constant integer value *)
  | Var of string (* A variable, identified by its name (string) *)
  | Plus of arith_expr * arith_expr (* Sum of two arithmetic expressions *)
  | Minus of
      arith_expr * arith_expr (* Difference of two arithmetic expressions *)
  | Times of arith_expr * arith_expr (* Product of two arithmetic expressions *)
[@@deriving show]

(*---- Boolean Expression Type ----*)
(* The type 'bool_expr' defines boolean expressions. *)
type bool_expr =
  | Bool of bool (* A boolean constant value (true or false) *)
  | And of bool_expr * bool_expr (* Logical AND of two boolean expressions *)
  | Not of bool_expr (* Logical NOT of a boolean expression *)
  | Less of
      arith_expr
      * arith_expr (* Less-than comparison between two arithmetic expressions *)
[@@deriving show]

(*---- Command Type ----*)
(* The 'command' type defines the possible commands in the language. *)
type command =
  | Skip (* Does nothing, a no-op *)
  | Assign of string * arith_expr
    (* Assign the result of an arithmetic expression to a variable *)
  | Seq of
      command * command (* Sequence of two commands to be executed in order *)
  | If of bool_expr * command * command
    (* Conditional execution of one of two commands based on a boolean
       expression *)
  | While of bool_expr * command
[@@deriving show]
(* Repeated execution of a command as long as a boolean expression is true *)

(*---- Program Type ----*)
(* The 'program' type is a tuple representing a program with:
      - An input variable name (string)
      - An output variable name (string)
      - A body of commands (command) *)
type program = Prog of string * string * command [@@deriving show]

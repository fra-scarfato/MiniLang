(* Memory is represented as a hash table (key-value pair) where keys are strings
   (variable names) and values are integers (the variable values). *)
type memory = (string, int) Hashtbl.t

(*---- Arithmetic Expression Type ----*)
(* The type 'operation' defines arithmetic expressions. *)
type operation =
  | Constant of int (* A constant integer value *)
  | Variable of string (* A variable, identified by its name (string) *)
  | Plus of operation * operation (* Sum of two arithmetic expressions *)
  | Minus of
      operation * operation (* Difference of two arithmetic expressions *)
  | Times of operation * operation (* Product of two arithmetic expressions *)
[@@deriving show]

(*---- Boolean Expression Type ----*)
(* The type 'bool_expr' defines boolean expressions. *)
type boolean =
  | Bool of bool (* A boolean constant value (true or false) *)
  | And of boolean * boolean (* Logical AND of two boolean expressions *)
  | Not of boolean (* Logical NOT of a boolean expression *)
  | Less of
      operation
      * operation (* Less-than comparison between two arithmetic expressions *)
[@@deriving show]

(*---- Command Type ----*)
(* The 'command' type defines the possible commands in the language. *)
type command =
  | Skip (* Does nothing, a no-op *)
  | Assign of string * operation
    (* Assign the result of an arithmetic expression to a variable *)
  | Seq of
      command * command (* Sequence of two commands to be executed in order *)
  | If of boolean * command * command
    (* Conditional execution of one of two commands based on a boolean
       expression *)
  | While of boolean * command
[@@deriving show]
(* Repeated execution of a command as long as a boolean expression is true *)

(*---- Program Type ----*)
(* The 'program' type is a tuple representing a program with:
      - An input variable name (string)
      - An output variable name (string)
      - A body of commands (command) *)
type program = Prog of string * string * command [@@deriving show]

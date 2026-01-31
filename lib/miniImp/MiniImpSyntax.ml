(* =============================================================================
 * MINIIMP SYNTAX: The Source Language
 * =============================================================================
 *
 * This module defines the abstract syntax for MiniImp, a simple imperative
 * programming language. Think of it as a minimal version of C or Pascal,
 * with just enough features to be interesting but simple enough to compile.
 *
 * DESIGN PHILOSOPHY: MINIMAL BUT COMPLETE
 * ----------------------------------------
 * MiniImp has exactly what you need for imperative programming:
 *   - Variables (mutable state)
 *   - Arithmetic (integers only, no floating point)
 *   - Conditionals (if-then-else)
 *   - Loops (while)
 *
 * What it DOESN'T have (intentionally):
 *   - Functions/procedures (would need stack management)
 *   - Arrays/pointers (would need heap and addressing)
 *   - Multiple types (would need type checking)
 *   - I/O statements (handled by program wrapper)
 *
 * THE EXPRESSION HIERARCHY:
 * -------------------------
 * We separate expressions into TWO types:
 *
 * 1. OPERATIONS (arithmetic) - produce integers
 *    Example: x + 5, y * 2
 *
 * 2. BOOLEANS (logical) - produce true/false
 *    Example: x < 10, b and c
 *
 * Why separate? Type safety! We can't write nonsense like "5 + true" or
 * "if (x + 1) then...". The OCaml type system catches these at compile time.
 *
 * THE COMMAND STRUCTURE:
 * ----------------------
 * Commands are the "statements" of MiniImp. They modify state but don't
 * return values (unlike expressions).
 *
 * - Skip: The "do nothing" command (like empty block or pass in Python)
 * - Assign: Update a variable (the ONLY way to change state)
 * - Seq: Sequential composition (do A, then do B)
 * - If: Conditional branching
 * - While: Looping (the ONLY control flow that can iterate)
 *
 * Note the RECURSIVE structure: Seq(Seq(Seq(...))) for multiple statements.
 * This is how the parser naturally builds sequences. Our CFG construction
 * will flatten this into basic blocks.
 *
 * PROGRAM WRAPPER:
 * ----------------
 * A MiniImp program is: Prog(input_var, output_var, body)
 *
 * This defines the I/O interface:
 *   - input_var: Name of variable to receive the input value
 *   - output_var: Name of variable whose final value is the output
 *   - body: The command sequence to execute
 *
 * Example:
 *   Prog("n", "result", 
 *     Seq(Assign("result", Constant 0),
 *         While(Less(Variable "result", Variable "n"),
 *               Assign("result", Plus(Variable "result", Constant 1)))))
 *
 * This computes: result = n (the hard way, by counting up)
 *)

module StringMap = Map.Make (String)

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

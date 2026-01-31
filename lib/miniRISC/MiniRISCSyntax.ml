(* =============================================================================
 * MINIRIS SYNTAX: The Target Language
 * =============================================================================
 *
 * This module defines the abstract syntax for MiniRISC, our low-level
 * register-based intermediate language. Think of it as a simplified
 * assembly language.
 *
 * THE INSTRUCTION SET:
 * --------------------
 * - LoadI: Load immediate constant into register
 * - BinRegOp: Binary operation with two register operands
 * - BinImmOp: Binary operation with register and immediate
 * - UnaryOp: Unary operation (not, copy)
 * - Load/Store: Explicit memory access via register indirect addressing
 * - Jump/CJump: Control flow (unconditional and conditional branches)
 *
 * EXAMPLE PROGRAM:
 *   loadi 5 => r1        # Load constant 5 into r1
 *   add r1 r_in => r2    # Add input to 5
 *   copy r2 => r_out     # Copy result to output
 *)

module VarMap = Map.Make (String)

(* Common Types for MiniRisc *)

(* Types for registers and labels, wrapped in a variant for extra type safety *)
type register = Register of string
type label = Label of string

(* A mapping from strings to strings, used for registers, etc. *)
type register_map = register VarMap.t

(* Binary and unary operators *)
type brop = Add | Sub | Mult | And | Less
type biop = AddI | SubI | MultI | AndI
type urop = Not | Copy

(* The command type representing instructions in MiniRisc *)
type command =
  | Nop
  | BinRegOp of brop * register * register * register (* brop r1 r2 => r3 *)
  | BinImmOp of biop * register * int * register (* biop r1 n => r2 *)
  | UnaryOp of urop * register * register (* urop r1 => r2 *)
  | Load of register * register (* load r1 => r2 *)
  | LoadI of int * register (* loadI n => r *)
  | Store of register * register (* store r1 => r2 *)
  | Jump of label (* jump l *)
  | CJump of register * label * label (* cjump r true_label false_label *)

type risc_block = { label : label; commands : command list; term : command }

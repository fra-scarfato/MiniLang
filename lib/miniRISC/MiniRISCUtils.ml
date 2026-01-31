open MiniRISCSyntax

(* =============================================================================
 * MINIRIS UTILITIES: Register Analysis and Pretty Printing
 * =============================================================================
 *
 * This module provides the foundational utilities used throughout the
 * register allocation and compilation pipeline. It answers two key questions:
 *
 * 1. WHICH REGISTERS DOES THIS INSTRUCTION TOUCH?
 *    - Used by dataflow analysis to track variable liveness
 *    - Used by coalescing to understand register dependencies
 *
 * 2. HOW DO WE DISPLAY THIS CODE TO HUMANS?
 *    - Pretty printing for debugging
 *    - Consistent formatting across all phases
 *
 * THE "USED" VS "DEFINED" DISTINCTION:
 * -------------------------------------
 * This is fundamental to dataflow analysis:
 *
 * - USED (read): Registers whose values are READ by this instruction
 *   Example: add r1 r2 => r3    used = {r1, r2}
 *
 * - DEFINED (written): Registers whose values are WRITTEN by this instruction
 *   Example: add r1 r2 => r3    defined = {r3}
 *
 * WHY IT MATTERS:
 * If we know instruction I uses r1, then r1 must be "live" (defined and not
 * dead) at the point just BEFORE I executes. This drives liveness analysis.
 *
 * If instruction I defines r3, then any previous value in r3 is "killed"
 * (overwritten) at point AFTER I executes. This tells us when registers die.
 *)

(* ========== Special Registers ========== *)

let input_register = Register "r_in"
let output_register = Register "r_out"

(* ========== Shared Data Structures ========== *)

module RegisterSet = Set.Make (struct
  type t = register

  let compare = compare
end)

module RegisterMap = Map.Make (struct
  type t = register

  let compare = compare
end)

(* ========== Register Analysis Functions ========== *)

(* Get all registers used (read) by an instruction *)
let get_used_registers = function
  | LoadI _ -> [] (* Immediate load reads nothing *)
  | UnaryOp (_, src, _) -> [ src ] (* Reads source *)
  | BinRegOp (_, r1, r2, _) -> [ r1; r2 ] (* Reads both operands *)
  | BinImmOp (_, r1, _, _) -> [ r1 ] (* Reads the register operand *)
  | Load (addr_reg, _) ->
      [ addr_reg ] (* Reads the address register to fetch memory *)
  | Store (val_reg, addr_reg) ->
      [ val_reg; addr_reg ] (* Reads value to store and address *)
  | CJump (cond_reg, _, _) -> [ cond_reg ] (* Reads condition *)
  | Nop | Jump _ -> [] (* Reads nothing *)

(* Get all registers defined (written) by an instruction *)
let get_defined_registers = function
  | LoadI (_, dst) -> [ dst ] (* Writes immediate to dest *)
  | UnaryOp (_, _, dst) -> [ dst ] (* Writes result to dest *)
  | BinRegOp (_, _, _, dst) -> [ dst ] (* Writes result to dest *)
  | BinImmOp (_, _, _, dst) -> [ dst ] (* Writes result to dest *)
  | Load (_, dst) -> [ dst ] (* Writes loaded memory value to dest *)
  | Store _ -> [] (* Writes to memory, no register changes *)
  | Nop | Jump _ | CJump _ -> [] (* Control flow writes no registers *)

(* ========== Register Generation ========== *)

let make_register n = Register (Printf.sprintf "r%d" n)
let make_label n = Label (Printf.sprintf "L%d" n)

(* Logging utility *)
let log_verbose verbose fmt =
  Printf.ksprintf (fun s -> if verbose then print_endline s else ()) fmt

(* ========== String Conversion Functions ========== *)

let string_of_register (Register r) = r
let string_of_label (Label l) = l

let string_of_brop = function
  | Add -> "add"
  | Sub -> "sub"
  | Mult -> "mult"
  | And -> "and"
  | Less -> "less"

let string_of_biop = function
  | AddI -> "addi"
  | SubI -> "subi"
  | MultI -> "multi"
  | AndI -> "andi"

let string_of_urop = function Not -> "not" | Copy -> "copy"

let string_of_command = function
  | Nop -> "nop"
  | BinRegOp (op, r1, r2, r3) ->
      Printf.sprintf "%s %s %s => %s" (string_of_brop op)
        (string_of_register r1) (string_of_register r2) (string_of_register r3)
  | BinImmOp (op, r, n, rd) ->
      Printf.sprintf "%s %s %d => %s" (string_of_biop op) (string_of_register r)
        n (string_of_register rd)
  | UnaryOp (op, r1, r2) ->
      Printf.sprintf "%s %s => %s" (string_of_urop op) (string_of_register r1)
        (string_of_register r2)
  | Load (r1, r2) ->
      Printf.sprintf "load %s => %s" (string_of_register r1)
        (string_of_register r2)
  | LoadI (n, r) ->
      (* Format large numbers (>= 0x1000) as hex for readability *)
      if n >= 0x1000 then
        Printf.sprintf "loadi 0x%x => %s" n (string_of_register r)
      else Printf.sprintf "loadi %d => %s" n (string_of_register r)
  | Store (r1, r2) ->
      Printf.sprintf "store %s => %s" (string_of_register r1)
        (string_of_register r2)
  | Jump lbl -> Printf.sprintf "jump %s" (string_of_label lbl)
  | CJump (r, ltrue, lfalse) ->
      Printf.sprintf "cjump %s %s %s" (string_of_register r)
        (string_of_label ltrue) (string_of_label lfalse)

let string_of_regset set =
  let regs = RegisterSet.elements set in
  "{" ^ String.concat ", " (List.map string_of_register regs) ^ "}"

(* ========== Instruction Points (for fine-grained liveness analysis) ========== *)

(* Instruction index: represents position within a block *)
type instruction_index =
  | Entry (* Block entry point (before first instruction) *)
  | AfterInstr of int (* After executing instruction N *)

(* Instruction point: (block_id, position_in_block) *)
type instr_point = int * instruction_index

module InstrPoint = struct
  type t = instr_point

  let compare (b1, idx1) (b2, idx2) =
    match compare b1 b2 with
    | 0 -> (
        match (idx1, idx2) with
        | Entry, Entry -> 0
        | Entry, AfterInstr _ -> -1 (* Entry comes before all instructions *)
        | AfterInstr _, Entry -> 1
        | AfterInstr i1, AfterInstr i2 -> compare i1 i2
      )
    | c -> c

  let to_string (bid, idx) =
    match idx with
    | Entry -> Printf.sprintf "Block %d Entry" bid
    | AfterInstr i -> Printf.sprintf "Block %d After instr %d" bid i
end

module InstrPointMap = Map.Make (InstrPoint)
module InstrPointSet = Set.Make (InstrPoint)

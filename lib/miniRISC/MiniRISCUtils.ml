open MiniRISCSyntax

(* ========== Special Registers ========== *)

let input_register = Register "r_in"
let output_register = Register "r_out"

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

(* Check if register appears in instruction *)
let uses_register reg instr = List.mem reg (get_used_registers instr)
let defines_register reg instr = List.mem reg (get_defined_registers instr)

(* ========== Register Generation ========== *)

let make_register n = Register (Printf.sprintf "r%d" n)
let make_label n = Label (Printf.sprintf "L%d" n)

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
  | LoadI (n, r) -> Printf.sprintf "loadi %d => %s" n (string_of_register r)
  | Store (r1, r2) ->
      Printf.sprintf "store %s => %s" (string_of_register r1)
        (string_of_register r2)
  | Jump lbl -> Printf.sprintf "jump %s" (string_of_label lbl)
  | CJump (r, ltrue, lfalse) ->
      Printf.sprintf "cjump %s %s %s" (string_of_register r)
        (string_of_label ltrue) (string_of_label lfalse)

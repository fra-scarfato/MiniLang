module Map = Map.Make (String)

type register_map = string Map.t ref
type register = Register of string
type label = Label of string
type brop = Add | Sub | Mult | And | Less
type biop = AddI | SubI | MultI | AndI
type urop = Not | Copy

type command =
  | Nop
  | BinRegOp of brop * register * register * register (* brop r1 r2 => r3 *)
  | BinImmOp of biop * register * int * register (* biop r1 n => r2 *)
  | UnaryOp of urop * register * register (* urop r1 => r2 *)
  | Load of register * register (* load r1 => r2 *)
  | LoadI of int * register (* loadI n => r *)
  | Store of register * register (* store r1 => r2 *)
  | Jump of label (* jump l*)
  | CJump of register * label * label (* cjump r true_label false_label *)

type risc_block = { label : label; commands : command list; term : command }
type block_map = risc_block Map.t
type risc_cfg = { nodes : block_map; entry : label; exit : label }

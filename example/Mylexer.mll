(* code to be copied in the scanner module *)
{
open Myparser  (* <-- where we define the tokens *)
exception LexingError of string
}

(* some named RExp *)
let integer = ['0'-'9']['0'-'9']*
let white = [' ' '\t']+ | '\r' | '\n' | "\r\n"

(* lexing rules *)
rule read = parse
| white {read lexbuf}
| integer {INT(int_of_string (Lexing.lexeme lexbuf))}
| "+" {PLUS}
| "-" {MINUS}
| "*" {TIMES}
| eof {EOF}
| _ { raise (LexingError (Lexing.lexeme lexbuf)) }
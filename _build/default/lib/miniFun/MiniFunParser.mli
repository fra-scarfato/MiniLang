
(* The type of tokens. *)

type token = 
  | VAR of (string)
  | TRUE
  | TIMES
  | THEN
  | RPAREN
  | REC
  | PLUS
  | NOT
  | MINUS
  | LPAREN
  | LET
  | LESS
  | INT of (int)
  | IN
  | IF
  | FUN
  | FALSE
  | EQUAL
  | EOF
  | ELSE
  | ARROW
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val main: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (MiniFunSyntax.term)

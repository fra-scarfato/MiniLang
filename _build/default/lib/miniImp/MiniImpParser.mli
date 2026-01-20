
(* The type of tokens. *)

type token = 
  | WHILE
  | VAR of (string)
  | TRUE of (bool)
  | TIMES
  | THEN
  | SKIP
  | SEMICOLON
  | RPAREN
  | PLUS
  | OUTPUT
  | NOT
  | MINUS
  | LPAREN
  | LESS
  | INT of (int)
  | IF
  | FALSE of (bool)
  | EQUAL
  | EOF
  | ELSE
  | DO
  | DEF
  | AS
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val prg: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (MiniImpSyntax.program)

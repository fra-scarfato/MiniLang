{
  open MiniFunParser
  exception LexingError of string
}

let digit = ['0'-'9']
let integer = '-'? digit+
let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"
let letter = ['a'-'z' 'A'-'Z']
let variable = letter (letter | digit)*

rule read = parse
  | white       { read lexbuf }
  | newline     { read lexbuf }
  | "true"      { TRUE }
  | "false"     { FALSE }
  | "fun"       { FUN }
  | "->"        { ARROW }
  | "if"        { IF }
  | "then"      { THEN }
  | "else"      { ELSE }
  | "let"       { LET }
  | "rec"       { REC }
  | "in"        { IN }
  | "+"         { PLUS }
  | "-"         { MINUS }
  | "*"         { TIMES }
  | "and"       { AND }
  | "not"       { NOT }
  | "<"         { LESS }
  | "="         { EQUAL }
  | "("         { LPAREN }
  | ")"         { RPAREN }
  | integer     {
      let lexeme = Lexing.lexeme lexbuf in
      INT (int_of_string lexeme)
    }
  | variable    {
      let lexeme = Lexing.lexeme lexbuf in
      VAR lexeme
    }
  | eof         { EOF }
  | _ as ch     {
      raise (LexingError ("Unknown character: " ^ Char.escaped ch))
    }

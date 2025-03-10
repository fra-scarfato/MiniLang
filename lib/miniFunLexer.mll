{
  open MiniFunParser
  open Logger
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
  | newline     { log_message "[miniFunLexer]" "NEWLINE"; read lexbuf }
  | "true"      { log_message "[miniFunLexer]" "TRUE"; TRUE }
  | "false"     { log_message "[miniFunLexer]" "FALSE"; FALSE }
  | "fun"       { log_message "[miniFunLexer]" "FUN"; FUN }
  | "->"        { log_message "[miniFunLexer]" "ARROW"; ARROW }
  | "if"        { log_message "[miniFunLexer]" "IF"; IF }
  | "then"      { log_message "[miniFunLexer]" "THEN"; THEN }
  | "else"      { log_message "[miniFunLexer]" "ELSE"; ELSE }
  | "let"       { log_message "[miniFunLexer]" "LET"; LET }
  | "rec"       { log_message "[miniFunLexer]" "REC"; REC }
  | "in"        { log_message "[miniFunLexer]" "IN"; IN }
  | "+"         { log_message "[miniFunLexer]" "PLUS"; PLUS }
  | "-"         { log_message "[miniFunLexer]" "MINUS"; MINUS }
  | "*"         { log_message "[miniFunLexer]" "TIMES"; TIMES }
  | "and"       { log_message "[miniFunLexer]" "AND"; AND }
  | "not"       { log_message "[miniFunLexer]" "NOT"; NOT }
  | "<"         { log_message "[miniFunLexer]" "LESS"; LESS }
  | "="         { log_message "[miniFunLexer]" "EQUAL"; EQUAL }
  | "("         { log_message "[miniFunLexer]" "LPAREN"; LPAREN }
  | ")"         { log_message "[miniFunLexer]" "RPAREN"; RPAREN }
  | integer     {
      let lexeme = Lexing.lexeme lexbuf in
      log_message "[miniFunLexer]" ("INT " ^ lexeme);
      INT (int_of_string lexeme)
    }
  | variable    {
      let lexeme = Lexing.lexeme lexbuf in
      log_message "[miniFunLexer]" ("VAR " ^ lexeme);
      VAR lexeme
    }
  | eof         { log_message "[miniFunLexer]" "EOF"; EOF }
  | _ as ch     {
      log_message "[miniFunLexer]" ("ERROR " ^ Char.escaped ch);
      raise (LexingError ("Unknown character: " ^ Char.escaped ch))
    }

{
    open MiniImpParser
    exception LexingError of string 
}

(* Lexical rules *)
let digit = ['0'-'9']
let integer = '-'? digit+
let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"
let letter = ['a'-'z' 'A'-'Z']
let variable = letter (letter | digit)*

(* Main lexing rules *)
rule read = parse
    (* Skip whitespaces *)
    | white      { read lexbuf }
    
    (* Skip newlines *)
    | newline    { read lexbuf }

    (* Boolean literals *)
    | "true"     { TRUE true }
    | "false"    { TRUE false }

    (* Operators and special symbols *)
    | "+"        { PLUS }
    | "-"        { MINUS }
    | "*"        { TIMES }
    | "and"      { AND }
    | "not"      { NOT }
    | "<"        { LESS }

    (* Keywords for the language syntax *)
    | "skip"     { SKIP }
    | "if"       { IF }
    | "then"     { THEN }
    | "else"     { ELSE }
    | "while"    { WHILE }
    | "do"       { DO }
    | "def main with input" { DEF }
    | "output"   { OUTPUT }
    | "as"       { AS }
    | "="        { EQUAL }
    | "("        { LPAREN }
    | ")"        { RPAREN }
    | ";"        { SEMICOLON }

    (* Identifiers and literals *)
    | integer    { 
        let lexeme = Lexing.lexeme lexbuf in
        INT (int_of_string lexeme) 
    }
    | variable   {
        let lexeme = Lexing.lexeme lexbuf in
        VAR lexeme
    }

    | eof        { EOF }
    | _ as ch    { 
        raise (LexingError ("Unknown character: " ^ Char.escaped ch))
    }
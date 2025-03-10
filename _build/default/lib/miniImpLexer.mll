{
    open MiniImpParser
    open Logger
    exception LexingError of string 
}

(*---- Lexical Rules ----*)
(* Definitions of regular expressions for the lexer. These patterns match the various tokens in the MiniImp language. *)

(* 'digit' matches any single digit character. *)
let digit = ['0'-'9']
(* 'integer' matches an optional minus sign followed by one or more digits (a negative or positive integer). *)
let integer = '-'? digit+
(* 'white' matches one or more spaces or tabs. Used to ignore whitespace. *)
let white = [' ' '\t']+
(* 'newline' matches any form of newlines (Unix, Windows, or old Mac-style). *)
let newline = '\r' | '\n' | "\r\n"
(* 'letter' matches any lowercase or uppercase letter. Used for variable names. *)
let letter = ['a'-'z' 'A'-'Z']
(* 'variable' matches a letter followed by zero or more letters or digits. Used for variable names. *)
let variable = letter (letter | digit)*

(*---- Main Lexing Rule ----*)
(* The main lexer rule. This is a recursive function that reads the input and matches tokens. *)
rule read = parse
    (* Match whitespace characters and skip them efficiently *)
    | white      { read lexbuf }  (* No logging for whitespace, just skip *)
    
    (* Match newlines and log them only when needed *)
    | newline    { log_message "[Lexer]" "NEWLINE"; read lexbuf }

    (* Boolean literals *)
    | "true"     { log_message "[Lexer]" "BOOL true"; TRUE true }
    | "false"    { log_message "[Lexer]" "BOOL false"; TRUE false }

    (* Operators and special symbols *)
    | "+"        { log_message "[Lexer]" "PLUS"; PLUS }
    | "-"        { log_message "[Lexer]" "MINUS"; MINUS }
    | "*"        { log_message "[Lexer]" "TIMES"; TIMES }
    | "and"      { log_message "[Lexer]" "AND"; AND }
    | "not"      { log_message "[Lexer]" "NOT"; NOT }
    | "<"        { log_message "[Lexer]" "LESS"; LESS }

    (* Keywords for the language syntax *)
    | "skip"     { log_message "[Lexer]" "SKIP"; SKIP }
    | "if"       { log_message "[Lexer]" "IF"; IF }
    | "then"     { log_message "[Lexer]" "THEN"; THEN }
    | "else"     { log_message "[Lexer]" "ELSE"; ELSE }
    | "while"    { log_message "[Lexer]" "WHILE"; WHILE }
    | "do"       { log_message "[Lexer]" "DO"; DO }
    | "def main with input" { log_message "[Lexer]" "DEF"; DEF }
    | "output"   { log_message "[Lexer]" "OUTPUT"; OUTPUT }
    | "as"       { log_message "[Lexer]" "AS"; AS }
    | "="        { log_message "[Lexer]" "EQUAL"; EQUAL }
    | "("        { log_message "[Lexer]" "LPAREN"; LPAREN }
    | ")"        { log_message "[Lexer]" "RPAREN"; RPAREN }
    | ";"        { log_message "[Lexer]" "SEMICOLON"; SEMICOLON }

    (* Handle integer values with efficient conversion *)
    | integer    { 
        let lexeme = Lexing.lexeme lexbuf in
        log_message "[Lexer]" ("INTEGER " ^ lexeme);
        INT (int_of_string lexeme) 
    }

    (* Handle variables *)
    | variable   {
        let lexeme = Lexing.lexeme lexbuf in
        log_message "[Lexer]" ("VARIABLE " ^ lexeme);
        VAR lexeme
    }

    (* Handle EOF and log it *)
    | eof        { log_message "[Lexer]" "EOF"; EOF }

    (* Catch unknown characters efficiently with a custom error message *)
    | _ as ch    { 
        log_message "[Lexer]" ("ERROR " ^ Char.escaped ch);
        raise (LexingError ("Unknown character: " ^ Char.escaped ch))
    }
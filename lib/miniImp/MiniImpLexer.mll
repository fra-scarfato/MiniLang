(* =============================================================================
 * MINIIMP LEXER: Breaking Text into Tokens
 * =============================================================================
 *
 * PURPOSE: Transform source text into a stream of tokens for the parser.
 *
 * DESIGN CHOICES:
 * ---------------
 * 1. **WHITESPACE HANDLING**: We skip all whitespace (spaces, tabs, newlines)
 *
 * 2. **KEYWORD vs IDENTIFIER**: Keywords like "if", "while" are matched FIRST
 *    If we matched identifiers first, "if" would be treated as a variable!
 *    OCamllex matches patterns in ORDER, so we list keywords before variables.
 *
 * 3. **NEGATIVE NUMBERS**: We handle "-" in the integer pattern (integer = '-'? digit+)
 *    This means "-5" is ONE token, not two (MINUS and INT(5)).
 *    Alternative: Handle in parser (more flexible but more complex).
 *
 * 4. **NO COMMENTS**: MiniImp doesn't support comments.    
 *
 * 5. **MULTI-WORD KEYWORDS**: "def main with input" is a SINGLE token (DEF)
 *    This is unusual! Most languages use separate keywords.
 *    We do this to enforce a specific program structure syntactically.
 *
 * ERROR HANDLING:
 * ---------------
 * Any character not matching a pattern raises LexingError.
 * This gives immediate feedback on invalid characters like "@" or "$".
 *)

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
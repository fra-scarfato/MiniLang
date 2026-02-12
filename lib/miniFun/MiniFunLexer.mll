(* =============================================================================
 * MINIFUN LEXER: TOKENIZING SOURCE CODE FOR FUNCTIONAL PROGRAMS
 * =============================================================================
 *
 * The lexer (lexical analyzer) is the first phase of parsing. It reads the
 * raw text of a program and breaks it into TOKENS - meaningful units like
 * keywords, identifiers, numbers, operators, etc.
 *
 * TOKEN DESIGN DECISIONS:
 * -----------------------
 * 1. Keywords vs Identifiers: "fun", "let", "if" are reserved keywords,
 *    not valid variable names. This prevents ambiguity.
 *
 * 2. Integer Literals: We support negative numbers directly in the lexer
 *    (-42 is one token). Alternative would be to treat minus as operator,
 *    but that complicates parsing of negative literals.
 *
 * 3. Whitespace: Ignored completely. MiniFun is not whitespace-sensitive
 *    (unlike Python). "let x = 5" and "let   x=5" are identical.
 *
 * 4. No Comments: This lexer doesn't support comments in source code.
 *    Production lexers would handle (* comments *) and skip them.
 *
 * ERROR HANDLING:
 * ---------------
 * Unknown characters raise a LexingError exception. A production lexer
 * would report the source location (line and column) of the error.
 *
 * EXAMPLE TOKEN STREAM:
 * ---------------------
 * Input:  "fun x -> x + 1"
 * Output: [FUN, VAR("x"), ARROW, VAR("x"), PLUS, INT(1), EOF]
 *
 * Input:  "if true then 42 else -1"
 * Output: [IF, TRUE, THEN, INT(42), ELSE, INT(-1), EOF]
 *)

{
  open MiniFunParser
  exception LexingError of string
}

(* Regular expression definitions for character classes *)
let digit = ['0'-'9']
let integer = '-'? digit+              (* Optional minus sign for negatives *)
let white = [' ' '\t']+                (* Spaces and tabs *)
let newline = '\r' | '\n' | "\r\n"     (* All newline conventions *)
let letter = ['a'-'z' 'A'-'Z']
let variable = letter (letter | digit)* (* Identifiers: start with letter *)

rule read = parse
  | white       { read lexbuf }        (* Skip whitespace, keep lexing *)
  | newline     { read lexbuf }        (* Skip newlines, keep lexing *)
  | "true"      { TRUE }               (* Boolean literal true *)
  | "false"     { FALSE }              (* Boolean literal false *)
  | "fun"       { FUN }                (* Function keyword *)
  | "->"        { ARROW }              (* Function arrow *)
  | "if"        { IF }                 (* Conditional keyword *)
  | "then"      { THEN }               (* Then branch *)
  | "else"      { ELSE }               (* Else branch *)
  | "let"       { LET }                (* Let binding *)
  | "letfun"    { LETFUN }             (* Recursive function *)
  | "in"        { IN }                 (* In keyword (for let/letfun) *)
  | "+"         { PLUS }               (* Addition operator *)
  | "-"         { MINUS }              (* Subtraction operator *)
  | "*"         { TIMES }              (* Multiplication operator *)
  | "and"       { AND }                (* Boolean and operator *)
  | "not"       { NOT }                (* Boolean not operator *)
  | "<"         { LESS }               (* Less-than comparison *)
  | "="         { EQUAL }              (* Equals (for let binding, not comparison) *)
  | "("         { LPAREN }             (* Left parenthesis *)
  | ")"         { RPAREN }             (* Right parenthesis *)
  | integer     {                      (* Integer literal (possibly negative) *)
      let lexeme = Lexing.lexeme lexbuf in
      INT (int_of_string lexeme)
    }
  | variable    {                      (* Identifier (variable or function name) *)
      let lexeme = Lexing.lexeme lexbuf in
      VAR lexeme
    }
  | eof         { EOF }                (* End of file *)
  | _ as ch     {                      (* Unknown character - error *)
      raise (LexingError ("Unknown character: " ^ Char.escaped ch))
    }

(* =============================================================================
 * MINIIMP PARSER: Building Abstract Syntax Trees
 * =============================================================================
 *
 * PURPOSE: Transform a stream of tokens into a structured AST.
 *
 * KEY DESIGN DECISIONS:
 * ---------------------
 * 1. **PROGRAM STRUCTURE**: Every MiniImp program MUST start with:
 *      def main with input <var> output <var> as <body>
 *    This is ENFORCED by the grammar, not just a convention.
 *
 * 2. **COMMAND SEQUENCING**: We use RIGHT-ASSOCIATIVE sequences:
 *      c1; c2; c3  →  Seq(c1, Seq(c2, c3))
 *    This creates a right-leaning tree. It's natural for recursive parsing.
 *
 * 3. **STATEMENT TERMINATORS**: Semicolons are REQUIRED after statements.
 *    But we allow optional trailing semicolons (see command_list rules).
 *    This is a usability compromise: strict syntax but forgiving formatting.
 *
 * 4. **PARENTHESES in COMMANDS**: We allow (c1; c2; c3) to group commands.
 *    This is useful for disambiguation and clarity, even though semantically
 *    it's just a Seq.
 *
 * 5. **EXPRESSION PRECEDENCE**: We use Menhir's %left declarations:
 *      - Arithmetic: * > +,- (standard math rules)
 *      - Boolean: NOT > AND (like ! and && in C)
 *    This means "a + b * c" parses as "a + (b * c)" automatically!
 *
 * 6. **NEGATIVE NUMBERS**: We handle "-" specially in the 'int' rule:
 *      int: INT | MINUS INT
 *    This distinguishes unary minus (in numbers) from binary minus (in expressions).
 *    It's a bit redundant with the lexer, but ensures correct precedence.
 *
 * AMBIGUITY RESOLUTION:
 * ---------------------
 * The grammar comments highlight critical disambiguation:
 *   - "if b then c1 else c2; c3" → grouped as "(if..else); c3"
 *   - "while b do c1; c2" → grouped as "(while...); c2"
 *
 * This is the DANGLING ELSE/SEMICOLON problem. We solve it by making
 * IF and WHILE accept a SINGLE command, not a command_list.
 * Sequences require explicit parentheses or nested structure.
 *)

%{
    open MiniImpSyntax
%}

%token <int> INT
%token <string> VAR
%token <bool> TRUE FALSE
%token PLUS MINUS TIMES
%token AND NOT LESS
%token SKIP IF THEN ELSE WHILE DO
%token DEF OUTPUT AS LPAREN RPAREN EQUAL SEMICOLON EOF

(*
   NOT has higher precedence than AND.
   not a AND b -------> (not a) AND b
*)
%left AND
%left NOT

(*
   TIMES has higher precedence than PLUS and MINUS.
   a + b * c -------> a + (b * c)
*)
%left PLUS MINUS
%left TIMES

%start <program> prg

%%
prg:
    | DEF; input = VAR; OUTPUT; output = VAR; AS; p = command_list; EOF     {Prog(input, output, p)}

(*
   Disambiguation:
   - if b then c1 else c2; c3 -------> (if b then c1 else c2); c3
   - while b do c1; c2 --------------> (while b do c1); c2
*)
command_list:
    | c1 = command; SEMICOLON; c2 = command_list;      {Seq(c1, c2)}
    | c = command; SEMICOLON;                          {c}
    | c = command;                                     {c}

command:
    | x = VAR; EQUAL; p = a_expr                                      {Assign(x, p)}
    | IF; cond = b_expr; THEN; p1 = command; ELSE; p2 = command       {If(cond, p1, p2)}
    | WHILE; cond = b_expr; DO; p = command                           {While(cond, p)}
    | LPAREN; p = command_list; RPAREN                                  {p}
    | SKIP                                                             {Skip}

a_expr:
    | LPAREN; p = a_expr; RPAREN                            {p}
    | n = int                                               {Constant n}
    | v = VAR                                               {Variable v}
    | p1 = a_expr; PLUS; p2 = a_expr                        {Plus(p1, p2)}
    | p1 = a_expr; MINUS; p2 = a_expr                       {Minus(p1, p2)}
    | p1 = a_expr; TIMES; p2 = a_expr                       {Times(p1, p2)}

b_expr:
    | TRUE                                                  {Bool true}
    | FALSE                                                 {Bool false}
    | NOT; p = b_expr                                       {Not p}
    | p1 = b_expr; AND; p2 = b_expr                         {And(p1, p2)}
    | p1 = a_expr; LESS; p2 = a_expr                        {Less(p1, p2)}

int:
    | p = INT                                               {p}
    | MINUS; p = INT                                        {-p}

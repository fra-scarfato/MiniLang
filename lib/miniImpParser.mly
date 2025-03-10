%{
    open MiniImpTypes
    open Logger
%}



(* Token declarations: These tokens are the building blocks that the parser will recognize. *)
%token <int> INT
%token <string> VAR
%token <bool> TRUE FALSE
%token PLUS MINUS TIMES
%token AND NOT LESS
%token SKIP IF THEN ELSE WHILE DO
%token DEF OUTPUT AS LPAREN RPAREN EQUAL SEMICOLON EOF

(* Precedence and associativity of operators: Defines how the parser will handle different operator priorities. *)
%left SEMICOLON
(* Nested "while" loop are not permitted if the parenthesis are not speciifed *)
(* Higher precedence then ";" because (while stmt); stmt *)
%nonassoc DO
(* Nested "if-else" are permitted and the "else" branch matches with closest preceding "if" *)
%left ELSE

%left AND
%nonassoc NOT

%left PLUS MINUS
%left TIMES

(* Start symbol for the parser: The entry point of the grammar. The parser will begin parsing a program. *)
%start <program> prg

%%
(*---- Grammar rules ----*)
(* These define how tokens are grouped into meaningful constructs. Each rule represents a specific part of the MiniImp language. *)

(* Program rule: The structure of the MiniImp program, consisting of an input variable, an output variable, and a body of commands. *)
prg:
    | DEF; input = VAR; OUTPUT; output = VAR; AS; p = command; EOF     {log_message "[Parser]" "Prog"; Prog(input, output, p)}

(* Command rule: Defines various commands in the MiniImp language, such as skip, assignment, sequence, conditionals, and loops. *)
command:
    | LPAREN; p = command; RPAREN                                   {log_message "[Parser]" "(p)"; p}
    | SKIP                                                          {log_message "[Parser]" "Skip"; Skip}
    | x = VAR; EQUAL; p = a_expr                                    {log_message "[Parser]" "Assign"; Assign(x, p)}
    | IF; cond = b_expr; THEN; p1 = command; ELSE; p2 = command     {log_message "[Parser]" "If"; If(cond, p1, p2)}
    | WHILE; cond = b_expr; DO; p = command                         {log_message "[Parser]" "While"; While(cond, p)}
    | p1 = command; SEMICOLON; p2 = command                         {log_message "[Parser]" "Seq"; Seq(p1, p2)}

(* Arithmetic expression rule: Defines arithmetic operations like addition, subtraction, multiplication, and number or variable references. *)
a_expr:
    | LPAREN; p = a_expr; RPAREN                            {log_message "[Parser]" "(p)"; p}
    | n = int                                               {log_message "[Parser]" "Num"; Num n}
    | v = VAR                                               {log_message "[Parser]" "Var"; Var v}
    | p1 = a_expr; PLUS; p2 = a_expr                        {log_message "[Parser]" "Plus"; Plus(p1, p2)}
    | p1 = a_expr; MINUS; p2 = a_expr                       {log_message "[Parser]" "Minus"; Minus(p1, p2)}
    | p1 = a_expr; TIMES; p2 = a_expr                       {log_message "[Parser]" "Times"; Times(p1, p2)}

(* Boolean expression rule: Defines boolean expressions, including boolean literals, negation, logical conjunction, and comparison. *)
b_expr:
    | TRUE                                                  {log_message "[Parser]" "true"; Bool true}
    | FALSE                                                 {log_message "[Parser]" "false"; Bool false}
    | NOT; p = b_expr                                       {log_message "[Parser]" "Not"; Not(p)}
    | p1 = b_expr; AND; p2 = b_expr                         {log_message "[Parser]" "And"; And(p1, p2)}
    | p1 = a_expr; LESS; p2 = a_expr                        {log_message "[Parser]" "Less"; Less(p1, p2)}

(* Integer rule: Defines how integer values are handled, including literals and negative numbers. *)
int:
    | p = INT                                               {log_message "[Parser]" "Int"; p}
    | MINUS; p = INT                                        {log_message "[Parser]" "Negative Int"; -p}

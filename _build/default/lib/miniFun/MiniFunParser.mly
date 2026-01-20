%{
open MiniFunSyntax
%}
%token <int> INT
%token <string> VAR
%token TRUE FALSE
%token PLUS MINUS TIMES AND NOT LESS
%token IF THEN ELSE
%token FUN ARROW
%token LET REC IN
%token EQUAL
%token LPAREN RPAREN
%token EOF

(*
  Precedence and associativity declarations solve shift/reduce conflicts
  by telling the parser how to handle operator precedence and associativity.
  Lower declarations = lower precedence.
*)

(*
  IN, ELSE, and ARROW have lowest precedence.
  This solves: "let x = 1 in x + 2" -------> let x = 1 in (x + 2)
  Not: (let x = 1 in x) + 2
  
  This solves: "if c then t1 else t2 + 3" -------> if c then t1 else (t2 + 3)
  Not: (if c then t1 else t2) + 3
  
  This solves: "fun x -> x + 1" -------> fun x -> (x + 1)
  Not: (fun x -> x) + 1
*)
%left IN ELSE ARROW

(*
  AND and NOT have higher precedence than IN/ELSE/ARROW but lower than arithmetic.
  This solves: "not a AND b" -------> (not a) AND b
  Not: not (a AND b)
*)
%left AND NOT

(*
  LESS has higher precedence than boolean operators but lower than arithmetic.
  This solves: "a + b LESS c + d" -------> (a + b) LESS (c + d)
  Not: a + (b LESS c) + d
*)
%left LESS

(*
  PLUS and MINUS have same precedence, left associative.
  This solves: "a - b + c" -------> (a - b) + c
  Not: a - (b + c)
*)
%left PLUS MINUS

(*
  TIMES has highest precedence among binary operators.
  This solves: "a + b * c" -------> a + (b * c)
  Not: (a + b) * c
*)
%left TIMES

%start <term> main
%%

main:
| t=expr EOF { t }

expr:
(*
  IF-THEN-ELSE: The %left ELSE declaration solves the dangling else problem.
  This solves: "if c1 then if c2 then t1 else t2" -------> if c1 then (if c2 then t1 else t2)
  Not: (if c1 then if c2 then t1) else t2
*)
| IF c=expr THEN t1=expr ELSE t2=expr { If(c, t1, t2) }

(*
  FUN: The %left ARROW declaration ensures function body extends as far right as possible.
  This solves: "fun x -> fun y -> x + y" -------> fun x -> (fun y -> (x + y))
  Not: (fun x -> fun y -> x) + y
*)
| FUN x=VAR ARROW t=expr { Fun(x, t) }

(*
  LET: The %left IN declaration ensures let body extends as far right as possible.
  This solves: "let x = 1 in let y = 2 in x + y" -------> let x = 1 in (let y = 2 in (x + y))
  Not: (let x = 1 in let y = 2 in x) + y
*)
| LET x=VAR EQUAL e=expr IN b=expr { Let(x, e, b) }

(*
  LET REC: Same as LET, the %left IN ensures proper scoping.
  This solves: "let rec f x = x in f 3 + 1" -------> let rec f x = x in ((f 3) + 1)
  Not: (let rec f x = x in f 3) + 1
*)
| LET REC f=VAR x=VAR EQUAL e=expr IN b=expr { LetFun(f, x, e, b) }

(*
  Binary operators: Precedence declarations handle these.
  PLUS/MINUS are left-associative with same precedence.
  TIMES has higher precedence than PLUS/MINUS.
  AND, LESS follow their declared precedences.
*)
| t1=expr PLUS t2=expr { BinOp(t1, Plus, t2) }
| t1=expr MINUS t2=expr { BinOp(t1, Minus, t2) }
| t1=expr TIMES t2=expr { BinOp(t1, Times, t2) }
| t1=expr LESS t2=expr { BinOp(t1, Less, t2) }
| t1=expr AND t2=expr { BinOp(t1, And, t2) }

(*
  NOT: Declared with %left NOT for precedence.
  This solves: "not a AND b" -------> (not a) AND b
*)
| NOT t=expr { UnaryOp(Not, t) }

| t=fun_app { t }

(*
  The fun_app rule solves the function application associativity problem.
  Function application is left-associative and has highest precedence.
  This solves: "f g h" -------> (f g) h
  Not: f (g h)
  
  By separating fun_app from atomic, we ensure that:
  - "f g + h" -------> (f g) + h (application binds tighter than operators)
  - Applications are chained left-to-right
*)
fun_app:
| t1=fun_app t2=atomic { FunApp(t1, t2) }
| t=atomic { t }

(*
  The atomic rule groups primitive values and parenthesized expressions.
  This prevents ambiguity by ensuring only simple, unambiguous terms
  can appear as function arguments or operands without parentheses.
  
  Parentheses solve: Explicit grouping overrides all precedence rules.
  "(a + b) * c" is unambiguous.
*)
atomic:
| LPAREN e=expr RPAREN { e }
| n=int { IntLit n }
| v=VAR { Var v }
| TRUE { BoolLit true }
| FALSE { BoolLit false }

(*
  The int rule handles negative integer literals.
  This solves: "(-5)" is parsed as a negative literal, not (- 5).
  Parentheses are required around negative literals to distinguish
  from the MINUS operator: "x-5" vs "x(-5)"
*)
int:
| n=INT { n }
| LPAREN; MINUS; n=INT; RPAREN { -n }
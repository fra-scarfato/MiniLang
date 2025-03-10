%{
open MiniFunAST
open Logger
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

(* Precedence and associativity declarations - ordered from lowest to highest *)
%nonassoc IN
%nonassoc ELSE
%right ARROW
%left AND
%nonassoc LESS
%left PLUS MINUS
%left TIMES
%nonassoc NOT
%nonassoc INT VAR TRUE FALSE
%nonassoc LPAREN

%start <term> main
%%

main:
  | t=term EOF { log_message "[miniFunParser]" "Parsed term"; t }

// Grammar for terms
term:
  | LPAREN t=term RPAREN { t }
  | NOT t=term             { UnaryOp(Not, t) }
  | INT                { log_message "[miniFunParser]" "Num"; Num $1 }
  | VAR                { log_message "[miniFunParser]" "Var"; Var $1 }
  | TRUE               { log_message "[miniFunParser]" "Bool true"; Bool true }
  | FALSE              { log_message "[miniFunParser]" "Bool false"; Bool false }
  | t1=term t2=term    { log_message "[miniFunParser]" "FunApp"; FunApp(t1, t2) }
  | t1=term PLUS t2=term   { BinOp(t1, Plus, t2) }
  | t1=term MINUS t2=term  { BinOp(t1, Minus, t2) }
  | t1=term TIMES t2=term  { BinOp(t1, Times, t2) }
  | t1=term LESS t2=term   { BinOp(t1, Less, t2) }
  | t1=term AND t2=term    { BinOp(t1, And, t2) }
  
  | IF c=term THEN t1=term ELSE t2=term { If(c, t1, t2) }
  | FUN x=VAR ARROW t=term { Fun(x, t) }
  | LET x=VAR EQUAL e=term IN b=term       { Let(x, e, b) }
  | LET REC f=VAR x=VAR EQUAL e=term IN b=term { LetFun(f, x, e, b) }
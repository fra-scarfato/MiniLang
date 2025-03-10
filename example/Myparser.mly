(* code to be copied in the scanner module *)
%{
	open Aexp
%}

(* tokens *)
%token <int> INT
%token PLUS MINUS TIMES EOF

(* start nonterminal *)
%start <aexp> prg

(* associativity in order of precedence *)
%left PLUS MINUS  /* lowest precedence */
%left TIMES       /* highest precedence */

%%

(* grammar *)
prg: 
    | t = trm; EOF               {t}
trm:
    | i = int                    {Intliteral i}
    | t1 = trm; PLUS; t2 = trm   {Plus (t1, t2)}
    | t1 = trm; MINUS; t2 = trm  {Minus (t1, t2)}
    | t1 = trm; TIMES; t2 = trm  {Times (t1, t2)}
int:
    | i = INT                    {i}
    | MINUS; i = int             {-i}
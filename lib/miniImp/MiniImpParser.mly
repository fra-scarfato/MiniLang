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

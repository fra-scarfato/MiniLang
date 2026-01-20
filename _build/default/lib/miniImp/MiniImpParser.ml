
module MenhirBasics = struct
  
  exception Error
  
  let _eRR =
    fun _s ->
      raise Error
  
  type token = 
    | WHILE
    | VAR of (
# 6 "lib/miniImp/MiniImpParser.mly"
       (string)
# 16 "lib/miniImp/MiniImpParser.ml"
  )
    | TRUE of (
# 7 "lib/miniImp/MiniImpParser.mly"
       (bool)
# 21 "lib/miniImp/MiniImpParser.ml"
  )
    | TIMES
    | THEN
    | SKIP
    | SEMICOLON
    | RPAREN
    | PLUS
    | OUTPUT
    | NOT
    | MINUS
    | LPAREN
    | LESS
    | INT of (
# 5 "lib/miniImp/MiniImpParser.mly"
       (int)
# 37 "lib/miniImp/MiniImpParser.ml"
  )
    | IF
    | FALSE of (
# 7 "lib/miniImp/MiniImpParser.mly"
       (bool)
# 43 "lib/miniImp/MiniImpParser.ml"
  )
    | EQUAL
    | EOF
    | ELSE
    | DO
    | DEF
    | AS
    | AND
  
end

include MenhirBasics

# 1 "lib/miniImp/MiniImpParser.mly"
  
    open MiniImpSyntax

# 61 "lib/miniImp/MiniImpParser.ml"

type ('s, 'r) _menhir_state = 
  | MenhirState05 : ('s _menhir_cell0_VAR _menhir_cell0_VAR, _menhir_box_prg) _menhir_state
    (** State 05.
        Stack shape : VAR VAR.
        Start symbol: prg. *)

  | MenhirState06 : (('s, _menhir_box_prg) _menhir_cell1_WHILE, _menhir_box_prg) _menhir_state
    (** State 06.
        Stack shape : WHILE.
        Start symbol: prg. *)

  | MenhirState09 : (('s, _menhir_box_prg) _menhir_cell1_NOT, _menhir_box_prg) _menhir_state
    (** State 09.
        Stack shape : NOT.
        Start symbol: prg. *)

  | MenhirState12 : (('s, _menhir_box_prg) _menhir_cell1_LPAREN, _menhir_box_prg) _menhir_state
    (** State 12.
        Stack shape : LPAREN.
        Start symbol: prg. *)

  | MenhirState16 : (('s, _menhir_box_prg) _menhir_cell1_a_expr, _menhir_box_prg) _menhir_state
    (** State 16.
        Stack shape : a_expr.
        Start symbol: prg. *)

  | MenhirState19 : (('s, _menhir_box_prg) _menhir_cell1_a_expr, _menhir_box_prg) _menhir_state
    (** State 19.
        Stack shape : a_expr.
        Start symbol: prg. *)

  | MenhirState21 : (('s, _menhir_box_prg) _menhir_cell1_a_expr, _menhir_box_prg) _menhir_state
    (** State 21.
        Stack shape : a_expr.
        Start symbol: prg. *)

  | MenhirState26 : (('s, _menhir_box_prg) _menhir_cell1_a_expr, _menhir_box_prg) _menhir_state
    (** State 26.
        Stack shape : a_expr.
        Start symbol: prg. *)

  | MenhirState29 : ((('s, _menhir_box_prg) _menhir_cell1_WHILE, _menhir_box_prg) _menhir_cell1_b_expr, _menhir_box_prg) _menhir_state
    (** State 29.
        Stack shape : WHILE b_expr.
        Start symbol: prg. *)

  | MenhirState31 : (('s, _menhir_box_prg) _menhir_cell1_VAR, _menhir_box_prg) _menhir_state
    (** State 31.
        Stack shape : VAR.
        Start symbol: prg. *)

  | MenhirState34 : (('s, _menhir_box_prg) _menhir_cell1_LPAREN, _menhir_box_prg) _menhir_state
    (** State 34.
        Stack shape : LPAREN.
        Start symbol: prg. *)

  | MenhirState35 : (('s, _menhir_box_prg) _menhir_cell1_IF, _menhir_box_prg) _menhir_state
    (** State 35.
        Stack shape : IF.
        Start symbol: prg. *)

  | MenhirState37 : ((('s, _menhir_box_prg) _menhir_cell1_IF, _menhir_box_prg) _menhir_cell1_b_expr, _menhir_box_prg) _menhir_state
    (** State 37.
        Stack shape : IF b_expr.
        Start symbol: prg. *)

  | MenhirState39 : (((('s, _menhir_box_prg) _menhir_cell1_IF, _menhir_box_prg) _menhir_cell1_b_expr, _menhir_box_prg) _menhir_cell1_command, _menhir_box_prg) _menhir_state
    (** State 39.
        Stack shape : IF b_expr command.
        Start symbol: prg. *)

  | MenhirState41 : (('s, _menhir_box_prg) _menhir_cell1_b_expr, _menhir_box_prg) _menhir_state
    (** State 41.
        Stack shape : b_expr.
        Start symbol: prg. *)

  | MenhirState46 : (('s, _menhir_box_prg) _menhir_cell1_command, _menhir_box_prg) _menhir_state
    (** State 46.
        Stack shape : command.
        Start symbol: prg. *)


and ('s, 'r) _menhir_cell1_a_expr = 
  | MenhirCell1_a_expr of 's * ('s, 'r) _menhir_state * (MiniImpSyntax.operation)

and ('s, 'r) _menhir_cell1_b_expr = 
  | MenhirCell1_b_expr of 's * ('s, 'r) _menhir_state * (MiniImpSyntax.boolean)

and ('s, 'r) _menhir_cell1_command = 
  | MenhirCell1_command of 's * ('s, 'r) _menhir_state * (MiniImpSyntax.command)

and ('s, 'r) _menhir_cell1_IF = 
  | MenhirCell1_IF of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_LPAREN = 
  | MenhirCell1_LPAREN of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_NOT = 
  | MenhirCell1_NOT of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_VAR = 
  | MenhirCell1_VAR of 's * ('s, 'r) _menhir_state * (
# 6 "lib/miniImp/MiniImpParser.mly"
       (string)
# 167 "lib/miniImp/MiniImpParser.ml"
)

and 's _menhir_cell0_VAR = 
  | MenhirCell0_VAR of 's * (
# 6 "lib/miniImp/MiniImpParser.mly"
       (string)
# 174 "lib/miniImp/MiniImpParser.ml"
)

and ('s, 'r) _menhir_cell1_WHILE = 
  | MenhirCell1_WHILE of 's * ('s, 'r) _menhir_state

and _menhir_box_prg = 
  | MenhirBox_prg of (MiniImpSyntax.program) [@@unboxed]

let _menhir_action_01 =
  fun p ->
    (
# 51 "lib/miniImp/MiniImpParser.mly"
                                                            (p)
# 188 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.operation))

let _menhir_action_02 =
  fun n ->
    (
# 52 "lib/miniImp/MiniImpParser.mly"
                                                            (Constant n)
# 196 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.operation))

let _menhir_action_03 =
  fun v ->
    (
# 53 "lib/miniImp/MiniImpParser.mly"
                                                            (Variable v)
# 204 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.operation))

let _menhir_action_04 =
  fun p1 p2 ->
    (
# 54 "lib/miniImp/MiniImpParser.mly"
                                                            (Plus(p1, p2))
# 212 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.operation))

let _menhir_action_05 =
  fun p1 p2 ->
    (
# 55 "lib/miniImp/MiniImpParser.mly"
                                                            (Minus(p1, p2))
# 220 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.operation))

let _menhir_action_06 =
  fun p1 p2 ->
    (
# 56 "lib/miniImp/MiniImpParser.mly"
                                                            (Times(p1, p2))
# 228 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.operation))

let _menhir_action_07 =
  fun () ->
    (
# 59 "lib/miniImp/MiniImpParser.mly"
                                                            (Bool true)
# 236 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.boolean))

let _menhir_action_08 =
  fun () ->
    (
# 60 "lib/miniImp/MiniImpParser.mly"
                                                            (Bool false)
# 244 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.boolean))

let _menhir_action_09 =
  fun p ->
    (
# 61 "lib/miniImp/MiniImpParser.mly"
                                                            (Not p)
# 252 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.boolean))

let _menhir_action_10 =
  fun p1 p2 ->
    (
# 62 "lib/miniImp/MiniImpParser.mly"
                                                            (And(p1, p2))
# 260 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.boolean))

let _menhir_action_11 =
  fun p1 p2 ->
    (
# 63 "lib/miniImp/MiniImpParser.mly"
                                                            (Less(p1, p2))
# 268 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.boolean))

let _menhir_action_12 =
  fun p x ->
    (
# 44 "lib/miniImp/MiniImpParser.mly"
                                                                      (Assign(x, p))
# 276 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.command))

let _menhir_action_13 =
  fun cond p1 p2 ->
    (
# 45 "lib/miniImp/MiniImpParser.mly"
                                                                      (If(cond, p1, p2))
# 284 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.command))

let _menhir_action_14 =
  fun cond p ->
    (
# 46 "lib/miniImp/MiniImpParser.mly"
                                                                      (While(cond, p))
# 292 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.command))

let _menhir_action_15 =
  fun p ->
    (
# 47 "lib/miniImp/MiniImpParser.mly"
                                                                        (p)
# 300 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.command))

let _menhir_action_16 =
  fun () ->
    (
# 48 "lib/miniImp/MiniImpParser.mly"
                                                                       (Skip)
# 308 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.command))

let _menhir_action_17 =
  fun c1 c2 ->
    (
# 39 "lib/miniImp/MiniImpParser.mly"
                                                       (Seq(c1, c2))
# 316 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.command))

let _menhir_action_18 =
  fun c ->
    (
# 40 "lib/miniImp/MiniImpParser.mly"
                                                       (c)
# 324 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.command))

let _menhir_action_19 =
  fun c ->
    (
# 41 "lib/miniImp/MiniImpParser.mly"
                                                       (c)
# 332 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.command))

let _menhir_action_20 =
  fun p ->
    (
# 66 "lib/miniImp/MiniImpParser.mly"
                                                            (p)
# 340 "lib/miniImp/MiniImpParser.ml"
     : (int))

let _menhir_action_21 =
  fun p ->
    (
# 67 "lib/miniImp/MiniImpParser.mly"
                                                            (-p)
# 348 "lib/miniImp/MiniImpParser.ml"
     : (int))

let _menhir_action_22 =
  fun input output p ->
    (
# 31 "lib/miniImp/MiniImpParser.mly"
                                                                            (Prog(input, output, p))
# 356 "lib/miniImp/MiniImpParser.ml"
     : (MiniImpSyntax.program))

let _menhir_print_token : token -> string =
  fun _tok ->
    match _tok with
    | AND ->
        "AND"
    | AS ->
        "AS"
    | DEF ->
        "DEF"
    | DO ->
        "DO"
    | ELSE ->
        "ELSE"
    | EOF ->
        "EOF"
    | EQUAL ->
        "EQUAL"
    | FALSE _ ->
        "FALSE"
    | IF ->
        "IF"
    | INT _ ->
        "INT"
    | LESS ->
        "LESS"
    | LPAREN ->
        "LPAREN"
    | MINUS ->
        "MINUS"
    | NOT ->
        "NOT"
    | OUTPUT ->
        "OUTPUT"
    | PLUS ->
        "PLUS"
    | RPAREN ->
        "RPAREN"
    | SEMICOLON ->
        "SEMICOLON"
    | SKIP ->
        "SKIP"
    | THEN ->
        "THEN"
    | TIMES ->
        "TIMES"
    | TRUE _ ->
        "TRUE"
    | VAR _ ->
        "VAR"
    | WHILE ->
        "WHILE"

let _menhir_fail : unit -> 'a =
  fun () ->
    Printf.eprintf "Internal failure -- please contact the parser generator's developers.\n%!";
    assert false

include struct
  
  [@@@ocaml.warning "-4-37"]
  
  let _menhir_run_49 : type  ttv_stack. ttv_stack _menhir_cell0_VAR _menhir_cell0_VAR -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _v _tok ->
      match (_tok : MenhirBasics.token) with
      | EOF ->
          let MenhirCell0_VAR (_menhir_stack, output) = _menhir_stack in
          let MenhirCell0_VAR (_menhir_stack, input) = _menhir_stack in
          let p = _v in
          let _v = _menhir_action_22 input output p in
          MenhirBox_prg _v
      | _ ->
          _eRR ()
  
  let rec _menhir_run_06 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_WHILE (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState06 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | VAR _v ->
          _menhir_run_07 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | TRUE _ ->
          _menhir_run_08 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | NOT ->
          _menhir_run_09 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_10 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_12 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_13 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE _ ->
          _menhir_run_23 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_07 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let v = _v in
      let _v = _menhir_action_03 v in
      _menhir_goto_a_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_a_expr : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState31 ->
          _menhir_run_32 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState26 ->
          _menhir_run_27 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState06 ->
          _menhir_run_25 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState35 ->
          _menhir_run_25 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState41 ->
          _menhir_run_25 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState09 ->
          _menhir_run_25 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState21 ->
          _menhir_run_22 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState19 ->
          _menhir_run_20 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState16 ->
          _menhir_run_17 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState12 ->
          _menhir_run_15 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_32 : type  ttv_stack. ((ttv_stack, _menhir_box_prg) _menhir_cell1_VAR as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | TIMES ->
          let _menhir_stack = MenhirCell1_a_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_16 _menhir_stack _menhir_lexbuf _menhir_lexer
      | PLUS ->
          let _menhir_stack = MenhirCell1_a_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_19 _menhir_stack _menhir_lexbuf _menhir_lexer
      | MINUS ->
          let _menhir_stack = MenhirCell1_a_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_21 _menhir_stack _menhir_lexbuf _menhir_lexer
      | ELSE | EOF | RPAREN | SEMICOLON ->
          let MenhirCell1_VAR (_menhir_stack, _menhir_s, x) = _menhir_stack in
          let p = _v in
          let _v = _menhir_action_12 p x in
          _menhir_goto_command _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_16 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_a_expr -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState16 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | VAR _v ->
          _menhir_run_07 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | MINUS ->
          _menhir_run_10 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_12 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_13 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_10 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | INT _v ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let p = _v in
          let _v = _menhir_action_21 p in
          _menhir_goto_int _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_goto_int : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let n = _v in
      let _v = _menhir_action_02 n in
      _menhir_goto_a_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_12 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_LPAREN (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState12 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | VAR _v ->
          _menhir_run_07 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | MINUS ->
          _menhir_run_10 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_12 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_13 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_13 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let p = _v in
      let _v = _menhir_action_20 p in
      _menhir_goto_int _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_19 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_a_expr -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState19 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | VAR _v ->
          _menhir_run_07 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | MINUS ->
          _menhir_run_10 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_12 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_13 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_21 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_a_expr -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState21 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | VAR _v ->
          _menhir_run_07 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | MINUS ->
          _menhir_run_10 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_12 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_13 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_goto_command : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState29 ->
          _menhir_run_48 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState05 ->
          _menhir_run_45 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState46 ->
          _menhir_run_45 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState34 ->
          _menhir_run_45 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState39 ->
          _menhir_run_40 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState37 ->
          _menhir_run_38 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_48 : type  ttv_stack. ((ttv_stack, _menhir_box_prg) _menhir_cell1_WHILE, _menhir_box_prg) _menhir_cell1_b_expr -> _ -> _ -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_b_expr (_menhir_stack, _, cond) = _menhir_stack in
      let MenhirCell1_WHILE (_menhir_stack, _menhir_s) = _menhir_stack in
      let p = _v in
      let _v = _menhir_action_14 cond p in
      _menhir_goto_command _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_45 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | SEMICOLON ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | WHILE ->
              let _menhir_stack = MenhirCell1_command (_menhir_stack, _menhir_s, _v) in
              _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState46
          | VAR _v_0 ->
              let _menhir_stack = MenhirCell1_command (_menhir_stack, _menhir_s, _v) in
              _menhir_run_30 _menhir_stack _menhir_lexbuf _menhir_lexer _v_0 MenhirState46
          | SKIP ->
              let _menhir_stack = MenhirCell1_command (_menhir_stack, _menhir_s, _v) in
              _menhir_run_33 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState46
          | LPAREN ->
              let _menhir_stack = MenhirCell1_command (_menhir_stack, _menhir_s, _v) in
              _menhir_run_34 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState46
          | IF ->
              let _menhir_stack = MenhirCell1_command (_menhir_stack, _menhir_s, _v) in
              _menhir_run_35 _menhir_stack _menhir_lexbuf _menhir_lexer MenhirState46
          | EOF | RPAREN ->
              let c = _v in
              let _v = _menhir_action_18 c in
              _menhir_goto_command_list _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
          | _ ->
              _eRR ())
      | EOF | RPAREN ->
          let c = _v in
          let _v = _menhir_action_19 c in
          _menhir_goto_command_list _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_30 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s ->
      let _menhir_stack = MenhirCell1_VAR (_menhir_stack, _menhir_s, _v) in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | EQUAL ->
          let _menhir_s = MenhirState31 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | VAR _v ->
              _menhir_run_07 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | MINUS ->
              _menhir_run_10 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LPAREN ->
              _menhir_run_12 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | INT _v ->
              _menhir_run_13 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_33 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let _v = _menhir_action_16 () in
      _menhir_goto_command _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_34 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_LPAREN (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState34 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | WHILE ->
          _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | VAR _v ->
          _menhir_run_30 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | SKIP ->
          _menhir_run_33 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_34 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | IF ->
          _menhir_run_35 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_35 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_IF (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState35 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | VAR _v ->
          _menhir_run_07 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | TRUE _ ->
          _menhir_run_08 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | NOT ->
          _menhir_run_09 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_10 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_12 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_13 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE _ ->
          _menhir_run_23 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_08 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let _v = _menhir_action_07 () in
      _menhir_goto_b_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_b_expr : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState41 ->
          _menhir_run_42 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState35 ->
          _menhir_run_36 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState06 ->
          _menhir_run_28 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState09 ->
          _menhir_run_24 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_42 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_b_expr -> _ -> _ -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_b_expr (_menhir_stack, _menhir_s, p1) = _menhir_stack in
      let p2 = _v in
      let _v = _menhir_action_10 p1 p2 in
      _menhir_goto_b_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_36 : type  ttv_stack. ((ttv_stack, _menhir_box_prg) _menhir_cell1_IF as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_b_expr (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | THEN ->
          let _menhir_s = MenhirState37 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | WHILE ->
              _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | VAR _v ->
              _menhir_run_30 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | SKIP ->
              _menhir_run_33 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LPAREN ->
              _menhir_run_34 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | IF ->
              _menhir_run_35 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | _ ->
              _eRR ())
      | AND ->
          _menhir_run_41 _menhir_stack _menhir_lexbuf _menhir_lexer
      | _ ->
          _eRR ()
  
  and _menhir_run_41 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_b_expr -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState41 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | VAR _v ->
          _menhir_run_07 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | TRUE _ ->
          _menhir_run_08 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | NOT ->
          _menhir_run_09 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_10 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_12 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_13 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE _ ->
          _menhir_run_23 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_09 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _menhir_stack = MenhirCell1_NOT (_menhir_stack, _menhir_s) in
      let _menhir_s = MenhirState09 in
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | VAR _v ->
          _menhir_run_07 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | TRUE _ ->
          _menhir_run_08 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | NOT ->
          _menhir_run_09 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | MINUS ->
          _menhir_run_10 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | LPAREN ->
          _menhir_run_12 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | INT _v ->
          _menhir_run_13 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
      | FALSE _ ->
          _menhir_run_23 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
      | _ ->
          _eRR ()
  
  and _menhir_run_23 : type  ttv_stack. ttv_stack -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      let _v = _menhir_action_08 () in
      _menhir_goto_b_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_28 : type  ttv_stack. ((ttv_stack, _menhir_box_prg) _menhir_cell1_WHILE as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_b_expr (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | DO ->
          let _menhir_s = MenhirState29 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | WHILE ->
              _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | VAR _v ->
              _menhir_run_30 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | SKIP ->
              _menhir_run_33 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LPAREN ->
              _menhir_run_34 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | IF ->
              _menhir_run_35 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | _ ->
              _eRR ())
      | AND ->
          _menhir_run_41 _menhir_stack _menhir_lexbuf _menhir_lexer
      | _ ->
          _eRR ()
  
  and _menhir_run_24 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_NOT -> _ -> _ -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_NOT (_menhir_stack, _menhir_s) = _menhir_stack in
      let p = _v in
      let _v = _menhir_action_09 p in
      _menhir_goto_b_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_goto_command_list : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match _menhir_s with
      | MenhirState05 ->
          _menhir_run_49 _menhir_stack _v _tok
      | MenhirState46 ->
          _menhir_run_47 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState34 ->
          _menhir_run_43 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_47 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_command -> _ -> _ -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_command (_menhir_stack, _menhir_s, c1) = _menhir_stack in
      let c2 = _v in
      let _v = _menhir_action_17 c1 c2 in
      _menhir_goto_command_list _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_43 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_LPAREN -> _ -> _ -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      match (_tok : MenhirBasics.token) with
      | RPAREN ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_LPAREN (_menhir_stack, _menhir_s) = _menhir_stack in
          let p = _v in
          let _v = _menhir_action_15 p in
          _menhir_goto_command _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_40 : type  ttv_stack. (((ttv_stack, _menhir_box_prg) _menhir_cell1_IF, _menhir_box_prg) _menhir_cell1_b_expr, _menhir_box_prg) _menhir_cell1_command -> _ -> _ -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_command (_menhir_stack, _, p1) = _menhir_stack in
      let MenhirCell1_b_expr (_menhir_stack, _, cond) = _menhir_stack in
      let MenhirCell1_IF (_menhir_stack, _menhir_s) = _menhir_stack in
      let p2 = _v in
      let _v = _menhir_action_13 cond p1 p2 in
      _menhir_goto_command _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_38 : type  ttv_stack. (((ttv_stack, _menhir_box_prg) _menhir_cell1_IF, _menhir_box_prg) _menhir_cell1_b_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_command (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | ELSE ->
          let _menhir_s = MenhirState39 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | WHILE ->
              _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | VAR _v ->
              _menhir_run_30 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | SKIP ->
              _menhir_run_33 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LPAREN ->
              _menhir_run_34 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | IF ->
              _menhir_run_35 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_27 : type  ttv_stack. ((ttv_stack, _menhir_box_prg) _menhir_cell1_a_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | TIMES ->
          let _menhir_stack = MenhirCell1_a_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_16 _menhir_stack _menhir_lexbuf _menhir_lexer
      | PLUS ->
          let _menhir_stack = MenhirCell1_a_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_19 _menhir_stack _menhir_lexbuf _menhir_lexer
      | MINUS ->
          let _menhir_stack = MenhirCell1_a_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_21 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | DO | THEN ->
          let MenhirCell1_a_expr (_menhir_stack, _menhir_s, p1) = _menhir_stack in
          let p2 = _v in
          let _v = _menhir_action_11 p1 p2 in
          _menhir_goto_b_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_25 : type  ttv_stack. ttv_stack -> _ -> _ -> _ -> (ttv_stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_a_expr (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | TIMES ->
          _menhir_run_16 _menhir_stack _menhir_lexbuf _menhir_lexer
      | PLUS ->
          _menhir_run_19 _menhir_stack _menhir_lexbuf _menhir_lexer
      | MINUS ->
          _menhir_run_21 _menhir_stack _menhir_lexbuf _menhir_lexer
      | LESS ->
          let _menhir_s = MenhirState26 in
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | VAR _v ->
              _menhir_run_07 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | MINUS ->
              _menhir_run_10 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | LPAREN ->
              _menhir_run_12 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
          | INT _v ->
              _menhir_run_13 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
  and _menhir_run_22 : type  ttv_stack. ((ttv_stack, _menhir_box_prg) _menhir_cell1_a_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | TIMES ->
          let _menhir_stack = MenhirCell1_a_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_16 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | DO | ELSE | EOF | LESS | MINUS | PLUS | RPAREN | SEMICOLON | THEN ->
          let MenhirCell1_a_expr (_menhir_stack, _menhir_s, p1) = _menhir_stack in
          let p2 = _v in
          let _v = _menhir_action_05 p1 p2 in
          _menhir_goto_a_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_20 : type  ttv_stack. ((ttv_stack, _menhir_box_prg) _menhir_cell1_a_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | TIMES ->
          let _menhir_stack = MenhirCell1_a_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_16 _menhir_stack _menhir_lexbuf _menhir_lexer
      | AND | DO | ELSE | EOF | LESS | MINUS | PLUS | RPAREN | SEMICOLON | THEN ->
          let MenhirCell1_a_expr (_menhir_stack, _menhir_s, p1) = _menhir_stack in
          let p2 = _v in
          let _v = _menhir_action_04 p1 p2 in
          _menhir_goto_a_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_17 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_a_expr -> _ -> _ -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_a_expr (_menhir_stack, _menhir_s, p1) = _menhir_stack in
      let p2 = _v in
      let _v = _menhir_action_06 p1 p2 in
      _menhir_goto_a_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_15 : type  ttv_stack. ((ttv_stack, _menhir_box_prg) _menhir_cell1_LPAREN as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | TIMES ->
          let _menhir_stack = MenhirCell1_a_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_16 _menhir_stack _menhir_lexbuf _menhir_lexer
      | RPAREN ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_LPAREN (_menhir_stack, _menhir_s) = _menhir_stack in
          let p = _v in
          let _v = _menhir_action_01 p in
          _menhir_goto_a_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | PLUS ->
          let _menhir_stack = MenhirCell1_a_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_19 _menhir_stack _menhir_lexbuf _menhir_lexer
      | MINUS ->
          let _menhir_stack = MenhirCell1_a_expr (_menhir_stack, _menhir_s, _v) in
          _menhir_run_21 _menhir_stack _menhir_lexbuf _menhir_lexer
      | _ ->
          _eRR ()
  
  let _menhir_run_00 : type  ttv_stack. ttv_stack -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _tok = _menhir_lexer _menhir_lexbuf in
      match (_tok : MenhirBasics.token) with
      | DEF ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          (match (_tok : MenhirBasics.token) with
          | VAR _v ->
              let _menhir_stack = MenhirCell0_VAR (_menhir_stack, _v) in
              let _tok = _menhir_lexer _menhir_lexbuf in
              (match (_tok : MenhirBasics.token) with
              | OUTPUT ->
                  let _tok = _menhir_lexer _menhir_lexbuf in
                  (match (_tok : MenhirBasics.token) with
                  | VAR _v ->
                      let _menhir_stack = MenhirCell0_VAR (_menhir_stack, _v) in
                      let _tok = _menhir_lexer _menhir_lexbuf in
                      (match (_tok : MenhirBasics.token) with
                      | AS ->
                          let _menhir_s = MenhirState05 in
                          let _tok = _menhir_lexer _menhir_lexbuf in
                          (match (_tok : MenhirBasics.token) with
                          | WHILE ->
                              _menhir_run_06 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
                          | VAR _v ->
                              _menhir_run_30 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s
                          | SKIP ->
                              _menhir_run_33 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
                          | LPAREN ->
                              _menhir_run_34 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
                          | IF ->
                              _menhir_run_35 _menhir_stack _menhir_lexbuf _menhir_lexer _menhir_s
                          | _ ->
                              _eRR ())
                      | _ ->
                          _eRR ())
                  | _ ->
                      _eRR ())
              | _ ->
                  _eRR ())
          | _ ->
              _eRR ())
      | _ ->
          _eRR ()
  
end

let prg =
  fun _menhir_lexer _menhir_lexbuf ->
    let _menhir_stack = () in
    let MenhirBox_prg v = _menhir_run_00 _menhir_stack _menhir_lexbuf _menhir_lexer in
    v


module MenhirBasics = struct
  
  exception Error
  
  let _eRR =
    fun _s ->
      raise Error
  
  type token = 
    | WHILE
    | VAR of (
# 10 "lib/miniImpParser.mly"
       (string)
# 16 "lib/miniImpParser.ml"
  )
    | TRUE of (
# 11 "lib/miniImpParser.mly"
       (bool)
# 21 "lib/miniImpParser.ml"
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
# 9 "lib/miniImpParser.mly"
       (int)
# 37 "lib/miniImpParser.ml"
  )
    | IF
    | FALSE of (
# 11 "lib/miniImpParser.mly"
       (bool)
# 43 "lib/miniImpParser.ml"
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

# 1 "lib/miniImpParser.mly"
  
    open MiniImpTypes
    open Logger

# 62 "lib/miniImpParser.ml"

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

  | MenhirState39 : (('s, _menhir_box_prg) _menhir_cell1_command, _menhir_box_prg) _menhir_state
    (** State 39.
        Stack shape : command.
        Start symbol: prg. *)

  | MenhirState41 : (((('s, _menhir_box_prg) _menhir_cell1_IF, _menhir_box_prg) _menhir_cell1_b_expr, _menhir_box_prg) _menhir_cell1_command, _menhir_box_prg) _menhir_state
    (** State 41.
        Stack shape : IF b_expr command.
        Start symbol: prg. *)

  | MenhirState43 : (('s, _menhir_box_prg) _menhir_cell1_b_expr, _menhir_box_prg) _menhir_state
    (** State 43.
        Stack shape : b_expr.
        Start symbol: prg. *)


and ('s, 'r) _menhir_cell1_a_expr = 
  | MenhirCell1_a_expr of 's * ('s, 'r) _menhir_state * (MiniImpTypes.arith_expr)

and ('s, 'r) _menhir_cell1_b_expr = 
  | MenhirCell1_b_expr of 's * ('s, 'r) _menhir_state * (MiniImpTypes.bool_expr)

and ('s, 'r) _menhir_cell1_command = 
  | MenhirCell1_command of 's * ('s, 'r) _menhir_state * (MiniImpTypes.command)

and ('s, 'r) _menhir_cell1_IF = 
  | MenhirCell1_IF of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_LPAREN = 
  | MenhirCell1_LPAREN of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_NOT = 
  | MenhirCell1_NOT of 's * ('s, 'r) _menhir_state

and ('s, 'r) _menhir_cell1_VAR = 
  | MenhirCell1_VAR of 's * ('s, 'r) _menhir_state * (
# 10 "lib/miniImpParser.mly"
       (string)
# 168 "lib/miniImpParser.ml"
)

and 's _menhir_cell0_VAR = 
  | MenhirCell0_VAR of 's * (
# 10 "lib/miniImpParser.mly"
       (string)
# 175 "lib/miniImpParser.ml"
)

and ('s, 'r) _menhir_cell1_WHILE = 
  | MenhirCell1_WHILE of 's * ('s, 'r) _menhir_state

and _menhir_box_prg = 
  | MenhirBox_prg of (MiniImpTypes.program) [@@unboxed]

let _menhir_action_01 =
  fun p ->
    (
# 53 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "(p)"; p)
# 189 "lib/miniImpParser.ml"
     : (MiniImpTypes.arith_expr))

let _menhir_action_02 =
  fun n ->
    (
# 54 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "Num"; Num n)
# 197 "lib/miniImpParser.ml"
     : (MiniImpTypes.arith_expr))

let _menhir_action_03 =
  fun v ->
    (
# 55 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "Var"; Var v)
# 205 "lib/miniImpParser.ml"
     : (MiniImpTypes.arith_expr))

let _menhir_action_04 =
  fun p1 p2 ->
    (
# 56 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "Plus"; Plus(p1, p2))
# 213 "lib/miniImpParser.ml"
     : (MiniImpTypes.arith_expr))

let _menhir_action_05 =
  fun p1 p2 ->
    (
# 57 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "Minus"; Minus(p1, p2))
# 221 "lib/miniImpParser.ml"
     : (MiniImpTypes.arith_expr))

let _menhir_action_06 =
  fun p1 p2 ->
    (
# 58 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "Times"; Times(p1, p2))
# 229 "lib/miniImpParser.ml"
     : (MiniImpTypes.arith_expr))

let _menhir_action_07 =
  fun () ->
    (
# 62 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "true"; Bool true)
# 237 "lib/miniImpParser.ml"
     : (MiniImpTypes.bool_expr))

let _menhir_action_08 =
  fun () ->
    (
# 63 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "false"; Bool false)
# 245 "lib/miniImpParser.ml"
     : (MiniImpTypes.bool_expr))

let _menhir_action_09 =
  fun p ->
    (
# 64 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "Not"; Not(p))
# 253 "lib/miniImpParser.ml"
     : (MiniImpTypes.bool_expr))

let _menhir_action_10 =
  fun p1 p2 ->
    (
# 65 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "And"; And(p1, p2))
# 261 "lib/miniImpParser.ml"
     : (MiniImpTypes.bool_expr))

let _menhir_action_11 =
  fun p1 p2 ->
    (
# 66 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "Less"; Less(p1, p2))
# 269 "lib/miniImpParser.ml"
     : (MiniImpTypes.bool_expr))

let _menhir_action_12 =
  fun p ->
    (
# 44 "lib/miniImpParser.mly"
                                                                    (log_message "[Parser]" "(p)"; p)
# 277 "lib/miniImpParser.ml"
     : (MiniImpTypes.command))

let _menhir_action_13 =
  fun () ->
    (
# 45 "lib/miniImpParser.mly"
                                                                    (log_message "[Parser]" "Skip"; Skip)
# 285 "lib/miniImpParser.ml"
     : (MiniImpTypes.command))

let _menhir_action_14 =
  fun p x ->
    (
# 46 "lib/miniImpParser.mly"
                                                                    (log_message "[Parser]" "Assign"; Assign(x, p))
# 293 "lib/miniImpParser.ml"
     : (MiniImpTypes.command))

let _menhir_action_15 =
  fun cond p1 p2 ->
    (
# 47 "lib/miniImpParser.mly"
                                                                    (log_message "[Parser]" "If"; If(cond, p1, p2))
# 301 "lib/miniImpParser.ml"
     : (MiniImpTypes.command))

let _menhir_action_16 =
  fun cond p ->
    (
# 48 "lib/miniImpParser.mly"
                                                                    (log_message "[Parser]" "While"; While(cond, p))
# 309 "lib/miniImpParser.ml"
     : (MiniImpTypes.command))

let _menhir_action_17 =
  fun p1 p2 ->
    (
# 49 "lib/miniImpParser.mly"
                                                                    (log_message "[Parser]" "Seq"; Seq(p1, p2))
# 317 "lib/miniImpParser.ml"
     : (MiniImpTypes.command))

let _menhir_action_18 =
  fun p ->
    (
# 70 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "Int"; p)
# 325 "lib/miniImpParser.ml"
     : (int))

let _menhir_action_19 =
  fun p ->
    (
# 71 "lib/miniImpParser.mly"
                                                            (log_message "[Parser]" "Negative Int"; -p)
# 333 "lib/miniImpParser.ml"
     : (int))

let _menhir_action_20 =
  fun input output p ->
    (
# 40 "lib/miniImpParser.mly"
                                                                       (log_message "[Parser]" "Prog"; Prog(input, output, p))
# 341 "lib/miniImpParser.ml"
     : (MiniImpTypes.program))

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
      | MenhirState43 ->
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
          let _v = _menhir_action_14 p x in
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
          let _v = _menhir_action_19 p in
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
      let _v = _menhir_action_18 p in
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
      | MenhirState05 ->
          _menhir_run_48 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState29 ->
          _menhir_run_47 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState34 ->
          _menhir_run_45 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState41 ->
          _menhir_run_42 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState39 ->
          _menhir_run_40 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState37 ->
          _menhir_run_38 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_48 : type  ttv_stack. (ttv_stack _menhir_cell0_VAR _menhir_cell0_VAR as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | SEMICOLON ->
          let _menhir_stack = MenhirCell1_command (_menhir_stack, _menhir_s, _v) in
          _menhir_run_39 _menhir_stack _menhir_lexbuf _menhir_lexer
      | EOF ->
          let MenhirCell0_VAR (_menhir_stack, output) = _menhir_stack in
          let MenhirCell0_VAR (_menhir_stack, input) = _menhir_stack in
          let p = _v in
          let _v = _menhir_action_20 input output p in
          MenhirBox_prg _v
      | _ ->
          _eRR ()
  
  and _menhir_run_39 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_command -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState39 in
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
      let _v = _menhir_action_13 () in
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
      | MenhirState43 ->
          _menhir_run_44 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | MenhirState35 ->
          _menhir_run_36 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState06 ->
          _menhir_run_28 _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | MenhirState09 ->
          _menhir_run_24 _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok
      | _ ->
          _menhir_fail ()
  
  and _menhir_run_44 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_b_expr -> _ -> _ -> _ -> _ -> _menhir_box_prg =
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
          _menhir_run_43 _menhir_stack _menhir_lexbuf _menhir_lexer
      | _ ->
          _eRR ()
  
  and _menhir_run_43 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_b_expr -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer ->
      let _menhir_s = MenhirState43 in
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
          _menhir_run_43 _menhir_stack _menhir_lexbuf _menhir_lexer
      | _ ->
          _eRR ()
  
  and _menhir_run_24 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_NOT -> _ -> _ -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_NOT (_menhir_stack, _menhir_s) = _menhir_stack in
      let p = _v in
      let _v = _menhir_action_09 p in
      _menhir_goto_b_expr _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_47 : type  ttv_stack. ((ttv_stack, _menhir_box_prg) _menhir_cell1_WHILE, _menhir_box_prg) _menhir_cell1_b_expr -> _ -> _ -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_b_expr (_menhir_stack, _, cond) = _menhir_stack in
      let MenhirCell1_WHILE (_menhir_stack, _menhir_s) = _menhir_stack in
      let p = _v in
      let _v = _menhir_action_16 cond p in
      _menhir_goto_command _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_45 : type  ttv_stack. ((ttv_stack, _menhir_box_prg) _menhir_cell1_LPAREN as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      match (_tok : MenhirBasics.token) with
      | SEMICOLON ->
          let _menhir_stack = MenhirCell1_command (_menhir_stack, _menhir_s, _v) in
          _menhir_run_39 _menhir_stack _menhir_lexbuf _menhir_lexer
      | RPAREN ->
          let _tok = _menhir_lexer _menhir_lexbuf in
          let MenhirCell1_LPAREN (_menhir_stack, _menhir_s) = _menhir_stack in
          let p = _v in
          let _v = _menhir_action_12 p in
          _menhir_goto_command _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
      | _ ->
          _eRR ()
  
  and _menhir_run_42 : type  ttv_stack. (((ttv_stack, _menhir_box_prg) _menhir_cell1_IF, _menhir_box_prg) _menhir_cell1_b_expr, _menhir_box_prg) _menhir_cell1_command -> _ -> _ -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_command (_menhir_stack, _, p1) = _menhir_stack in
      let MenhirCell1_b_expr (_menhir_stack, _, cond) = _menhir_stack in
      let MenhirCell1_IF (_menhir_stack, _menhir_s) = _menhir_stack in
      let p2 = _v in
      let _v = _menhir_action_15 cond p1 p2 in
      _menhir_goto_command _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_40 : type  ttv_stack. (ttv_stack, _menhir_box_prg) _menhir_cell1_command -> _ -> _ -> _ -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _tok ->
      let MenhirCell1_command (_menhir_stack, _menhir_s, p1) = _menhir_stack in
      let p2 = _v in
      let _v = _menhir_action_17 p1 p2 in
      _menhir_goto_command _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok
  
  and _menhir_run_38 : type  ttv_stack. (((ttv_stack, _menhir_box_prg) _menhir_cell1_IF, _menhir_box_prg) _menhir_cell1_b_expr as 'stack) -> _ -> _ -> _ -> ('stack, _menhir_box_prg) _menhir_state -> _ -> _menhir_box_prg =
    fun _menhir_stack _menhir_lexbuf _menhir_lexer _v _menhir_s _tok ->
      let _menhir_stack = MenhirCell1_command (_menhir_stack, _menhir_s, _v) in
      match (_tok : MenhirBasics.token) with
      | SEMICOLON ->
          _menhir_run_39 _menhir_stack _menhir_lexbuf _menhir_lexer
      | ELSE ->
          let _menhir_s = MenhirState41 in
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

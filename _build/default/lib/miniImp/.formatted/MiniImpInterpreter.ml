(** [parse_arguments ()] Checks the command-line arguments and returns a tuple
    [(in_file_name, input_int)]. Expects 2 or 3 arguments: the input file name,
    an integer value, and an optional "log". Exits the program with an error
    message if the arguments are invalid.
    @return The input file name and the starting input value *)
let parse_arguments () =
  let argc = Array.length Sys.argv in
  if argc < 3 || argc > 4 then (
    prerr_endline "Usage: <input_file> <integer_value> [log]";
    exit 1
  );
  (* Enable logging if the third argument is "log" *)
  (* Logging removed *)
  let in_file_name = Sys.argv.(1) in
  let input_n_str = Sys.argv.(2) in
  let input_int =
    try int_of_string input_n_str
    with Failure _ ->
      prerr_endline "Error: The second argument must be a valid integer.";
      exit 1
  in
  (in_file_name, input_int)

(** [read_program in_file_name] Opens the file [in_file_name], reads its
    content, and parses it into a program. Exits with an error if the file
    cannot be opened or if a syntax error occurs. The input channel is properly
    closed in all cases.
    @param in_file_name The input file name of the source code
    @return The program wrapped in the Abstract Syntax Tree *)
let read_program in_file_name =
  let in_file =
    try open_in in_file_name
    with Sys_error msg ->
      prerr_endline ("Error: Unable to open file " ^ in_file_name ^ ": " ^ msg);
      exit 1
  in
  let lexbuf = Lexing.from_channel in_file in
  let program =
    try MiniImpParser.prg MiniImpLexer.read lexbuf with
    | MiniImpParser.Error ->
        let pos = lexbuf.Lexing.lex_curr_p in
        Printf.eprintf
          "Syntax error at line %d, column %d: unexpected token '%s'\n"
          pos.Lexing.pos_lnum
          (pos.Lexing.pos_cnum - pos.Lexing.pos_bol)
          (Lexing.lexeme lexbuf);
        close_in in_file;
        exit 1
    | e ->
        prerr_endline ("Error: " ^ Printexc.to_string e);
        close_in in_file;
        exit 1
  in
  close_in in_file;
  program

(** [main ()] Entry point for the interpreter:
    - Parses the command-line arguments.
    - Reads and parses the program from the input file.
    - Builds the control flow graph (CFG) from the program.
    - Evaluates the program using the provided integer.
    - Prints the CFG (as a string) and the evaluation result. *)
let main () =
  (* Parse command-line arguments to obtain the input file name and starting
     integer *)
  let in_file_name, input_int = parse_arguments () in
  (* Logging removed *)

  (* Read and parse the program from the specified file *)
  let program = read_program in_file_name in

  (* Evaluate the program with the provided input integer *)
  let result = MiniImpEval.eval_program input_int program in

  Printf.printf "The result of the eveluation is: %i\n" result
(* Logging removed *)

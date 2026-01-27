open MiniLang

let parse_arguments () =
  (* Check if all the arguments are set *)
  if Array.length Sys.argv != 3 then (
    prerr_endline "Usage: <input_file> <integer_value>";
    exit 1
  );

  let in_file_name = Sys.argv.(1) in
  let input_n_str = Sys.argv.(2) in
  let input_int =
    (* Check if the second argument is an integer *)
    try int_of_string input_n_str
    with Failure _ ->
      prerr_endline "Error: The second argument must be a valid integer.";
      exit 1
  in
  (in_file_name, input_int)

let read_program in_file_name =
  (* Open the input file *)
  let in_file =
    try open_in in_file_name
    with Sys_error msg ->
      prerr_endline ("Error: Unable to open file " ^ in_file_name ^ ": " ^ msg);
      exit 1
  in
  (* Create a lexer buffer on the input file *)
  let lexbuf = Lexing.from_channel in_file in
  let program =
    (* Execute the lexer and the parser *)
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

let () =
  (* Parse command-line arguments to obtain the input file name and starting
     integer *)
  let in_file_name, input_int = parse_arguments () in

  (* Read and parse the program from the specified file *)
  let program = read_program in_file_name in

  (* Evaluate the program with the provided input integer *)
  let result = MiniImpEval.eval_program input_int program in

  Printf.printf "\nThe result of the evaluation is: %i\n" result

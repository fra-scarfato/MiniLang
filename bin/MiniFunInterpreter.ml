open MiniLang

let parse_arguments () =
  (* Check if the argument is set *)
  if Array.length Sys.argv != 2 then (
    prerr_endline "Usage: <input_file>";
    exit 1
  );

  let in_file_name = Sys.argv.(1) in
  in_file_name

let read_input_integer () =
  Printf.printf "Enter an integer: ";
  flush stdout;
  try
    let line = read_line () in
    int_of_string line
  with
  | End_of_file ->
      prerr_endline "Error: No input provided.";
      exit 1
  | Failure _ ->
      prerr_endline "Error: Invalid integer input.";
      exit 1

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
    try MiniFunParser.main MiniFunLexer.read lexbuf with
    | MiniFunParser.Error ->
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

let string_of_value (v : MiniFunSyntax.value) : string =
  match v with
  | MiniFunSyntax.Int n -> string_of_int n
  | MiniFunSyntax.Bool b -> string_of_bool b
  | MiniFunSyntax.Closure _ -> "<function>"

let () =
  (* Parse command-line arguments to obtain the input file name *)
  let in_file_name = parse_arguments () in

  (* Read and parse the program from the specified file *)
  let program = read_program in_file_name in

  (* Read the input integer from standard input *)
  let input_int = read_input_integer () in

  (* Evaluate the program *)
  try
    let result = MiniFunEval.eval_program input_int program in
    Printf.printf "\nThe result of the evaluation is: %s\n" (string_of_value result)
  with
  | Failure msg ->
      Printf.eprintf "Runtime error: %s\n" msg;
      exit 1
  | e ->
      Printf.eprintf "Unexpected error: %s\n" (Printexc.to_string e);
      exit 1

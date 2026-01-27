open MiniLang

(* ====================================================== *)
(* Types                                                  *)
(* ====================================================== *)

type args = {
  input_file : string;
  output_file : string;
  num_registers : int;
  check_safety : bool;
  optimize : bool;
  verbose : bool;
}

(* ====================================================== *)
(* Argument Parsing                                       *)
(* ====================================================== *)

let usage () =
  print_endline "Usage: MiniImpCompiler [OPTIONS] <num_registers> <input.minimp> <output.risc>";
  print_endline "";
  print_endline "Arguments:";
  print_endline "  <num_registers>  Number of target registers (must be >= 4)";
  print_endline "  <input.minimp>   Input MiniImp program file";
  print_endline "  <output.risc>    Output MiniRISC code file";
  print_endline "";
  print_endline "Options:";
  print_endline "  -s, --safety     Enable safety check for uninitialized variables";
  print_endline "  -O, --optimize   Enable register reduction optimization (uses liveness analysis)";
  print_endline "  -v, --verbose    Verbose output";
  print_endline "  -h, --help       Display this help";
  exit 0

let parse_arguments () =
  let argv = Array.to_list Sys.argv |> List.tl in

  let default =
    {
      input_file = "";
      output_file = "";
      num_registers = 0;
      check_safety = false;
      optimize = false;
      verbose = false;
    }
  in

  let rec parse acc positional = function
    | [] -> (acc, positional)
    | ("-s" | "--safety") :: rest -> parse { acc with check_safety = true } positional rest
    | ("-O" | "--optimize") :: rest -> parse { acc with optimize = true } positional rest
    | ("-v" | "--verbose") :: rest -> parse { acc with verbose = true } positional rest
    | ("-h" | "--help") :: _ -> usage ()
    | arg :: rest ->
        (* Collect positional arguments *)
        parse acc (positional @ [arg]) rest
  in

  let (args, positional) = parse default [] argv in

  (* Parse positional arguments: num_registers, input_file, output_file *)
  match positional with
  | [num_str; input; output] ->
      let num_registers =
        try int_of_string num_str
        with Failure _ ->
          Printf.eprintf "Error: Number of registers must be an integer\n";
          exit 1
      in
      if num_registers < 4 then (
        Printf.eprintf "Error: Number of registers must be >= 4 (got %d)\n" num_registers;
        exit 1
      );
      { args with num_registers; input_file = input; output_file = output }
  | _ ->
      Printf.eprintf "Error: Expected 3 arguments: <num_registers> <input.minimp> <output.risc>\n";
      usage ()


(* ====================================================== *)
(* File IO                                                *)
(* ====================================================== *)

let read_program filename =
  let chan =
    try open_in filename
    with Sys_error msg ->
      Printf.eprintf "Error: Cannot open %s: %s\n" filename msg;
      exit 1
  in
  let lexbuf = Lexing.from_channel chan in
  let program =
    try MiniImpParser.prg MiniImpLexer.read lexbuf with
    | MiniImpParser.Error ->
        let pos = lexbuf.Lexing.lex_curr_p in
        Printf.eprintf "Syntax error at line %d, column %d (token '%s')\n"
          pos.Lexing.pos_lnum
          (pos.Lexing.pos_cnum - pos.Lexing.pos_bol)
          (Lexing.lexeme lexbuf);
        close_in chan;
        exit 1
    | e ->
        Printf.eprintf "Error: %s\n" (Printexc.to_string e);
        close_in chan;
        exit 1
  in
  close_in chan;
  program

let write_output filename risc_program =
  let chan =
    try open_out filename
    with Sys_error msg ->
      Printf.eprintf "Error: Cannot create output file %s: %s\n" filename msg;
      exit 1
  in
  List.iter
    (fun instr ->
      Printf.fprintf chan "%s\n" (MiniRISCLinearize.string_of_labeled_instruction instr))
    risc_program;
  close_out chan

(* ====================================================== *)
(* Main                                                   *)
(* ====================================================== *)

let () =
  let args = parse_arguments () in

  if args.verbose then
    Printf.printf "Compiling %s → %s (target: %d registers)\n" 
      args.input_file args.output_file args.num_registers;

  let program = read_program args.input_file in
  let (MiniImpSyntax.Prog (input_var, output_var, _)) = program in

  let imp_cfg = MiniImpCFG.generate_cfg program in

  if args.verbose then (
    Printf.printf "\n=== MiniImp CFG ===\n";
    MiniImpCFG.print_cfg imp_cfg
  );

  let risc_cfg = MiniImpToRISC.translate_cfg input_var output_var imp_cfg in

  if args.verbose then (
    Printf.printf "\n=== MiniRISC CFG (initial translation) ===\n";
    MiniRISCCFG.print_risc_cfg risc_cfg
  );

  (* Safety check if requested *)
  if args.check_safety then (
    if args.verbose then Printf.printf "\n=== Safety Check ===\n";
    if not (DataflowAnalysis.DefiniteVariables.check_safety ~verbose:args.verbose risc_cfg) then (
      Printf.eprintf "\nCompilation failed: uninitialized register usage\n";
      exit 1
    )
  );

  (* Register allocation: always reduce to target number of registers *)
  (* With -O: use liveness analysis for intelligent allocation and dead store elimination *)
  (* Without -O: use simple frequency-based allocation without liveness *)
  let risc_cfg = 
    if args.optimize then (
      if args.verbose then 
        Printf.printf "\n=== Register Allocation with Liveness Optimization (target: %d registers) ===\n" args.num_registers;
      DataflowAnalysis.RegisterAllocation.reduce_registers ~verbose:args.verbose args.num_registers risc_cfg
    ) else (
      if args.verbose then
        Printf.printf "\n=== Simple Register Allocation (target: %d registers) ===\n" args.num_registers;
      DataflowAnalysis.RegisterAllocation.reduce_registers_simple ~verbose:args.verbose args.num_registers risc_cfg
    )
  in

  if args.verbose then (
    Printf.printf "\n=== MiniRISC CFG (final, %d registers) ===\n" args.num_registers;
    MiniRISCCFG.print_risc_cfg risc_cfg
  );

  (* Linearize CFG to sequential program *)
  let risc_program = MiniRISCLinearize.linearize_cfg risc_cfg in

  if args.verbose then (
    Printf.printf "\n=== MiniRISC Code ===\n";
    MiniRISCLinearize.print_risc_program risc_program;
    Printf.printf "\nTotal instructions: %d\n" (List.length risc_program)
  );

  (* Write output to file *)
  write_output args.output_file risc_program;
  
  if args.verbose then
    Printf.printf "\nCompilation successful! Output written to %s\n" args.output_file
  else
    Printf.printf "Compilation successful!\n"


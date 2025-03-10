let () =
  if Array.length Sys.argv != 2 then
    failwith "Argument MiniFun-program is needed";
  let in_file = open_in Sys.argv.(1) in
  let lexbuf = Lexing.from_channel in_file in
  let program = Myparser.prg Mylexer.read lexbuf in
  print_int (Aexp.eval program);
  print_newline ()

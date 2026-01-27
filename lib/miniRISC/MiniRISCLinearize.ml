open MiniRISCSyntax
open MiniRISCCFG

(* ========== Linearization ========== *)

(* A RISC program is a list of labeled blocks *)
type labeled_instruction = LabelDef of label | Instruction of command
type risc_program = labeled_instruction list

(* ========== Printing ========== *)

let string_of_labeled_instruction = function
  | LabelDef (Label l) -> l ^ ":"
  | Instruction cmd -> "  " ^ MiniRISCUtils.string_of_command cmd

let print_risc_program prog =
  List.iter
    (fun instr -> Printf.printf "%s\n" (string_of_labeled_instruction instr))
    prog

(* Logging utility *)
let log_verbose verbose fmt =
  Printf.ksprintf (fun s -> if verbose then print_endline s else ()) fmt

(* Convert RISC CFG to linear RISC code *)
let linearize_cfg ?(verbose = false) (cfg : risc_cfg) : risc_program =
  log_verbose verbose "\n=== CFG Linearization ===";

  (* Traverse blocks in ID order (could use other orderings) *)
  let blocks_list =
    BlockMap.fold (fun _ block acc -> block :: acc) cfg.blocks []
    |> List.sort (fun b1 b2 -> compare b1.id b2.id)
  in

  (* Generate code for each block *)
  let rec emit_blocks = function
    | [] -> []
    | block :: rest ->
        (* Use "main" label for entry block, otherwise use block's label *)
        let label =
          if block.id = cfg.entry then Label "main" else block.label
        in

        let label_def = [ LabelDef label ] in
        let instrs = List.map (fun cmd -> Instruction cmd) block.commands in
        let term =
          match block.terminator with Some t -> [ Instruction t ] | None -> []
        in

        label_def @ instrs @ term @ emit_blocks rest
  in

  let prog = emit_blocks blocks_list in

  if verbose then (
    log_verbose verbose "\n--- Linear Code ---";
    print_risc_program prog;
    log_verbose verbose "Total instructions: %d" (List.length prog)
  )
  else Printf.printf "Code linearized (%d instructions)\n" (List.length prog);

  prog

open MiniRISCSyntax
open MiniRISCUtils

(* ========== MiniRISC CFG Data Structures ========== *)

type block_id = int

type risc_cfg_block = {
  id : block_id;
  label : label;
  commands : command list;
  terminator : command option; (* Jump or CJump, None for exit block *)
}

type edge_label = Unconditional | True | False

module BlockMap = Map.Make (struct
  type t = block_id

  let compare = compare
end)

type risc_cfg = {
  blocks : risc_cfg_block BlockMap.t;
  edges : (block_id * edge_label) list BlockMap.t;
  entry : block_id;
  exit : block_id;
}

(* ========== Utility Functions ========== *)

let get_successors (cfg : risc_cfg) block_id =
  match BlockMap.find_opt block_id cfg.edges with
  | Some succs -> succs
  | None -> []

let get_predecessors (cfg : risc_cfg) block_id =
  BlockMap.fold
    (fun src succs acc ->
      if List.exists (fun (dst, _) -> dst = block_id) succs then src :: acc
      else acc
    )
    cfg.edges []

(* ========== Printing Functions ========== *)
let string_of_edge_label = function
  | Unconditional -> ""
  | True -> "[T]"
  | False -> "[F]"

let print_risc_cfg (cfg : risc_cfg) =
  Printf.printf "\n=== MiniRISC CFG (initial translation) ===\n";
  Printf.printf "Entry: %d | Exit: %d | Blocks: %d\n" cfg.entry cfg.exit
    (BlockMap.cardinal cfg.blocks);

  BlockMap.iter
    (fun id block ->
      Printf.printf "\nBlock %d [%s]:\n" id (string_of_label block.label);
      List.iter
        (fun cmd -> Printf.printf "  %s\n" (string_of_command cmd))
        block.commands;
      ( match block.terminator with
      | Some term -> Printf.printf "  %s\n" (string_of_command term)
      | None -> Printf.printf "  (no terminator)\n"
      );

      let succs = get_successors cfg id in
      if succs <> [] then begin
        Printf.printf "  Successors:\n";
        List.iter
          (fun (succ_id, label) ->
            Printf.printf "    --> %d %s\n" succ_id (string_of_edge_label label)
          )
          succs
      end
    )
    cfg.blocks;
  Printf.printf "====================\n"

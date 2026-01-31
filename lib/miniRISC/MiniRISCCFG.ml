open MiniRISCSyntax
open MiniRISCUtils

(* =============================================================================
 * MINIRIS CONTROL FLOW GRAPH (CFG)
 * =============================================================================
 *
 * This module defines the CFG representation for MiniRISC code. Unlike the
 * MiniImp CFG (which we BUILD from an AST), the MiniRISC CFG is RECEIVED
 * from the translation phase - we just define its structure here.
 *
 * KEY DIFFERENCES FROM MINIIMP CFG:
 * ----------------------------------
 * 1. NO STATEMENTS: Blocks contain low-level "commands" (instructions)
 * 2. EXPLICIT TERMINATORS: Each block has a terminator (Jump/CJump or None)
 * 3. LABELS: Blocks use explicit labels ("L1", "L2") for jumps
 *
 * Example:
 *   Block 5:
 *     add r1 r2 => r3
 *     less r3 r_in => r4
 *     terminator: cjump r4 L_true L_false
 *
 * THE DUAL REPRESENTATION:
 * ------------------------
 * We maintain BOTH:
 *   - blocks: Map from ID to block (for random access during analysis)
 *   - edges: Map from ID to successors (for traversal algorithms)
 *
 * This is redundant (edges are derivable from terminators) but makes
 * dataflow analysis faster - we don't have to parse terminators every time.
 *)

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

(* ---------------------------------------------------------------------------
 * get_successors: Find Blocks That Follow This One
 * ---------------------------------------------------------------------------
 *
 * Returns a list of (successor_id, edge_label) pairs for the given block.
 * Used by dataflow analysis to traverse the CFG forward.
 *
 * EXAMPLE:
 *   Block 5 has terminator: cjump r1 L_true L_false
 *   Result: [(block_for_L_true, True), (block_for_L_false, False)]
 *)
let get_successors (cfg : risc_cfg) block_id =
  match BlockMap.find_opt block_id cfg.edges with
  | Some succs -> succs
  | None -> []

(* ---------------------------------------------------------------------------
 * get_predecessors: Find Blocks That Lead to This One
 * ---------------------------------------------------------------------------
 *
 * Returns a list of block IDs that have edges pointing to this block.
 * Used by dataflow analysis to traverse the CFG backward.
 *
 * IMPLEMENTATION: Scans all edges to find those targeting this block.
 * This is O(n) but called infrequently (only during analysis setup).
 *)
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

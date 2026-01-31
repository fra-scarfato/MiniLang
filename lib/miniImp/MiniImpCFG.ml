open MiniImpSyntax

(* =============================================================================
 * CONTROL FLOW GRAPH (CFG) CONSTRUCTION
 * =============================================================================
 *
 * This module builds a Control Flow Graph from a MiniImp abstract syntax tree.
 * The CFG is the foundation for all further analysis and optimization.
 *
 * WHAT IS A CFG?
 * --------------
 * A CFG represents program structure as a graph where:
 *   - NODES (blocks): Sequences of straight-line code (no branches)
 *   - EDGES: Possible control flow between blocks (jumps, branches)
 *
 * Example program:
 *   if (x > 0) { y = 1 } else { y = 2 }
 *   z = y + 1
 *
 * CFG structure:
 *   Block 0 (entry): [skip]
 *   Block 1: [if test]  --True--> Block 2
 *                       --False--> Block 3
 *   Block 2: [y = 1] -------> Block 4
 *   Block 3: [y = 2] -------> Block 4
 *   Block 4: [z = y + 1] --> Block 5 (exit)
 *
 * THE CONSTRUCTION STRATEGY: "FLATTEN AND ACCUMULATE"
 * ----------------------------------------------------
 * We rejected a naive approach (create one block per statement, then merge)
 * in favor of a smarter strategy:
 *
 * 1. FLATTEN: Convert nested Seq(Seq(Seq(...))) into a flat list of statements
 * 2. ACCUMULATE: Build maximal basic blocks by accumulating straight-line code
 * 3. SPLIT: Only create a new block when we hit a branch point
 *
 * WHY THIS WAY?
 * -------------
 * - EFFICIENT: Creates exactly the blocks we need, no wasteful create-then-merge
 * - SAFE: No label aliasing bugs (we never destroy blocks that might be targets)
 * - CLEAN: Output is immediately optimal (maximal basic blocks)
 *
 * WHAT IS A "MAXIMAL BASIC BLOCK"?
 * ---------------------------------
 * A basic block is "maximal" if we can't extend it without violating the rule:
 * "no branches in the middle, at most one branch at the end".
 *
 * Example of NON-maximal (wasteful):
 *   Block 1: x = 1
 *   Block 2: y = 2
 *   Block 3: z = 3
 *
 * Example of MAXIMAL (optimal):
 *   Block 1: x = 1; y = 2; z = 3
 *
 * Our algorithm produces maximal blocks from the start.
 *)

(* ========== CFG Data Structures ========== *)

type block_id = int
type block = { id : block_id; stmts : command list }
type edge_label = Unconditional | True | False

module BlockMap = Map.Make (struct
  type t = block_id

  let compare = compare
end)

type cfg = {
  blocks : block BlockMap.t;
  edges : (block_id * edge_label) list BlockMap.t;
  entry : block_id;
  exit : block_id;
}

(* ========== Printing Functions ========== *)

let get_successors (cfg : cfg) block_id =
  match BlockMap.find_opt block_id cfg.edges with
  | Some succs -> succs
  | None -> []

let string_of_edge_label = function
  | Unconditional -> ""
  | True -> "[T]"
  | False -> "[F]"

let string_of_command_short = function
  | Skip -> "skip"
  | Assign (v, _) -> Printf.sprintf "%s := ..." v
  | Seq _ -> "seq"
  | If _ -> "if"
  | While _ -> "while"

let print_cfg cfg =
  Printf.printf "Entry: %d | Exit: %d | Blocks: %d\n" cfg.entry cfg.exit
    (BlockMap.cardinal cfg.blocks);

  BlockMap.iter
    (fun id block ->
      let stmts_str =
        block.stmts |> List.map string_of_command_short |> String.concat "; "
      in
      Printf.printf "\nBlock %d:\n  Stmts: %s\n" id stmts_str;

      let succs = get_successors cfg id in
      if succs <> [] then
        List.iter
          (fun (succ_id, label) ->
            Printf.printf "  --> %d %s\n" succ_id (string_of_edge_label label)
          )
          succs
      else Printf.printf "  (no successors)\n"
    )
    cfg.blocks;
  Printf.printf "-----------\n"
(* =============================================================================
 * CFG BUILDER: Functional Construction with Immutable Updates
 * =============================================================================
 *
 * The builder maintains the state of the CFG during construction. Unlike
 * typical imperative graph builders (using mutable refs), we use a pure
 * functional approach: each operation returns a NEW builder.
 *
 * WHY FUNCTIONAL?
 * ---------------
 * - SAFETY: Can't accidentally mutate shared state
 * - TESTABILITY: Each step is an independent, inspectable function call
 * - OCAML IDIOMATIC: Matches the functional programming style
 *
 * THE BUILDER STATE:
 * ------------------
 * - next_id: Counter for generating fresh block IDs
 * - blocks: Map from block_id to block (with statements)
 * - edges: Map from block_id to list of (successor_id, label)
 *
 * KEY OPERATIONS:
 * ---------------
 * - create_block: Allocate a fresh ID, add empty block
 * - append_stmt: Add a statement to the END of an existing block
 * - add_edge: Record that block A can flow to block B
 *
 * CRITICAL DESIGN CHOICE: Appending to Lists
 * -------------------------------------------
 * We use block.stmts @ [stmt] which is O(n) for each append. This might
 * seem inefficient, but:
 *   1. Basic blocks are typically SHORT (< 10 statements)
 *   2. We only append during construction, not during analysis
 *   3. The alternative (reverse accumulation) makes the code harder to read
 *
 * For an educational compiler, clarity trumps micro-optimization.
 *)
(* ========== Builder with Block Mutation Support ========== *)

type builder = {
  next_id : block_id;
  blocks : block BlockMap.t;
  edges : (block_id * edge_label) list BlockMap.t;
}

let create_builder () =
  { next_id = 0; blocks = BlockMap.empty; edges = BlockMap.empty }

(* Create a new empty block *)
let create_block builder =
  let id = builder.next_id in
  let block = { id; stmts = [] } in
  let new_builder =
    {
      builder with
      next_id = id + 1;
      blocks = BlockMap.add id block builder.blocks;
    }
  in
  (new_builder, id)

(* Append a statement to an EXISTING block (Functional Update) *)
let append_stmt builder block_id stmt =
  let block = BlockMap.find block_id builder.blocks in
  (* Note: We append to the end. Since lists are prepended, we will rev later *)
  let new_block = { block with stmts = block.stmts @ [ stmt ] } in
  { builder with blocks = BlockMap.add block_id new_block builder.blocks }

let add_edge builder src dst label =
  let current_edges =
    match BlockMap.find_opt src builder.edges with
    | Some edges -> edges
    | None -> []
  in
  {
    builder with
    edges = BlockMap.add src ((dst, label) :: current_edges) builder.edges;
  }

(* ========== 1. Flattening the AST (Crucial Step) ========== *)
(* Converts tree-like Seq(Seq(a,b), c) into [a; b; c] *)
let rec flatten_cmd cmd =
  match cmd with
  | Seq (c1, c2) -> flatten_cmd c1 @ flatten_cmd c2
  | _ -> [ cmd ]

(* ========== 2. Optimized CFG Generation ========== *)

(* Takes a list of commands and the current 'open' block. Returns the builder
   and the ID of the block where flow ends. *)
let rec gen_stmts builder current_block_id cmds =
  match cmds with
  | [] -> (builder, current_block_id)
  | cmd :: rest -> (
      match cmd with
      (* STRAIGHT LINE CODE: Just append and keep going *)
      | Skip ->
          let builder = append_stmt builder current_block_id cmd in
          gen_stmts builder current_block_id rest
      | Assign _ ->
          let builder = append_stmt builder current_block_id cmd in
          gen_stmts builder current_block_id rest
      (* BRANCHING: Append condition, Close block, Recurse *)
      | If (cond, then_branch, else_branch) ->
          (* 1. Put the 'If' stmt in the current block (as the terminator
             condition) *)
          let builder =
            append_stmt builder current_block_id (If (cond, Skip, Skip))
          in

          (* 2. Create Join block (where paths meet) with Skip *)
          let builder, join_id = create_block builder in
          let builder = append_stmt builder join_id Skip in

          (* 3. Process THEN path *)
          let builder, then_entry = create_block builder in
          let builder, then_end =
            gen_stmts builder then_entry (flatten_cmd then_branch)
          in
          let builder = add_edge builder current_block_id then_entry True in
          let builder = add_edge builder then_end join_id Unconditional in

          (* 4. Process ELSE path *)
          let builder, else_entry = create_block builder in
          let builder, else_end =
            gen_stmts builder else_entry (flatten_cmd else_branch)
          in
          let builder = add_edge builder current_block_id else_entry False in
          let builder = add_edge builder else_end join_id Unconditional in

          (* 5. Continue processing remaining commands in the JOIN block *)
          gen_stmts builder join_id rest
      (* LOOPS: Close current, Jump to Header, Recurse *)
      | While (cond, body) ->
          (* 1. Create Loop Header *)
          let builder, header_id = create_block builder in
          let builder =
            add_edge builder current_block_id header_id Unconditional
          in

          (* 2. Put 'While' condition in the Header *)
          let builder = append_stmt builder header_id (While (cond, Skip)) in

          (* 3. Create Loop Exit block with Skip *)
          let builder, exit_id = create_block builder in
          let builder = append_stmt builder exit_id Skip in

          (* 4. Process Body *)
          let builder, body_entry = create_block builder in
          let builder, body_end =
            gen_stmts builder body_entry (flatten_cmd body)
          in

          (* 5. Wire edges *)
          let builder = add_edge builder header_id body_entry True in
          (* Loop matches *)
          let builder = add_edge builder header_id exit_id False in
          (* Loop finishes *)
          let builder = add_edge builder body_end header_id Unconditional in
          (* Back edge *)

          (* 6. Continue in Exit block *)
          gen_stmts builder exit_id rest
      | Seq _ ->
          failwith "Should be flattened" (* Unreachable due to flatten_cmd *)
    )

(* ========== Public API ========== *)

(* Logging utility *)
let log_verbose verbose fmt =
  Printf.ksprintf (fun s -> if verbose then print_endline s else ()) fmt

let generate_cfg ?(verbose = false) (Prog (_, _, body)) =
  log_verbose verbose "\n=== MiniImp CFG Generation ===";

  let builder = create_builder () in

  (* Start with an Entry Block with Skip *)
  let builder, entry_id = create_block builder in
  let builder = append_stmt builder entry_id Skip in

  (* Flatten the body and generate *)
  let builder, final_id = gen_stmts builder entry_id (flatten_cmd body) in

  (* Create a dedicated Exit Block with Skip *)
  let builder, exit_id = create_block builder in
  let builder = append_stmt builder exit_id Skip in
  let builder = add_edge builder final_id exit_id Unconditional in

  let cfg =
    {
      blocks = builder.blocks;
      edges = builder.edges;
      entry = entry_id;
      exit = exit_id;
    }
  in

  if verbose then (
    log_verbose verbose "Generated %d blocks" (BlockMap.cardinal cfg.blocks);
    print_cfg cfg
  );

  cfg

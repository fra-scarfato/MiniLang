open MiniImpSyntax

(* =============================================================================
 * MINIIMP CONTROL FLOW GRAPH (CFG) CONSTRUCTION
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
 *)
(* ========== Builder with Block Mutation Support ========== *)

type builder = {
  next_id : block_id;
  blocks : block BlockMap.t;
  edges : (block_id * edge_label) list BlockMap.t;
}

(* ---------------------------------------------------------------------------
 * create_builder: Initialize an Empty CFG Builder
 * ---------------------------------------------------------------------------
 *
 * Creates a new builder with no blocks or edges.
 * The builder maintains monotonically increasing block IDs.
 *)
let create_builder () =
  { next_id = 0; blocks = BlockMap.empty; edges = BlockMap.empty }

(* ---------------------------------------------------------------------------
 * create_block: Allocate a New Empty Block
 * ---------------------------------------------------------------------------
 *
 * Generates a fresh block ID and adds an empty block to the builder.
 * Returns (updated_builder, new_block_id).
 *
 * PURE FUNCTIONAL: Returns a new builder instead of mutating.
 *)
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

(* ---------------------------------------------------------------------------
 * append_stmt: Add a Statement to an Existing Block
 * ---------------------------------------------------------------------------
 *
 * Appends a statement to the end of the specified block.
 * This is how we build maximal basic blocks (accumulate straight-line code).
 *
 * EFFICIENCY NOTE: We use block.stmts @ [stmt] which is O(n), but blocks
 * are typically very short (< 10 statements), so this is acceptable.
 *)
let append_stmt builder block_id stmt =
  let block = BlockMap.find block_id builder.blocks in
  let new_block = { block with stmts = block.stmts @ [ stmt ] } in
  { builder with blocks = BlockMap.add block_id new_block builder.blocks }

(* ---------------------------------------------------------------------------
 * add_edge: Connect Two Blocks with a Control Flow Edge
 * ---------------------------------------------------------------------------
 *
 * Adds an edge from source block to destination block with the given label.
 * Labels indicate the condition: True, False, or Unconditional.
 *
 * EXAMPLE:
 *   add_edge builder 1 2 True      // Block 1 -> Block 2 on true branch
 *   add_edge builder 1 3 False     // Block 1 -> Block 3 on false branch
 *)
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

(* =============================================================================
 * FLATTENING: From Nested Trees to Linear Lists
 * =============================================================================
 *
 * The parser produces deeply nested Seq structures:
 *   Seq(s1, Seq(s2, Seq(s3, Seq(s4, Seq(s5, ...)))))
 *
 * This is natural for recursive parsing but not the best for CFG construction.
 * We want a FLAT LIST: [s1; s2; s3; s4; s5]
 *
 * WHY FLATTEN?
 * ------------
 * 1. EASIER ITERATION: Process statements one-by-one without recursion
 * 2. MAXIMAL BLOCKS: Build longest possible basic blocks by accumulating
 * 3. SIMPLICITY: No need to handle tree structure during CFG building
 *
 * THE ALGORITHM:
 * --------------
 * We do a LEFT-BIASED FLATTENING:
 *   - If we see Seq(left, right), recurse on BOTH sides
 *   - If we see a non-Seq statement, that's a leaf - keep it
 *
 * CRITICAL: We preserve execution order (left before right).
 *
 * EXAMPLE:
 *   Input:  Seq(Seq(s1, s2), Seq(s3, s4))
 *   Output: [s1; s2; s3; s4]
 *
 * WHY NOT KEEP THE TREE?
 * ----------------------
 * We COULD build the CFG directly from the nested structure, but:
 *   - More complex code (handle Seq at every step)
 *   - Harder to optimize (can't easily see statement boundaries)
 *   - Mixing parsing concerns with CFG construction
 *
 * Flatten-first is the SEPARATION OF CONCERNS principle: one pass to
 * simplify structure, another pass to build CFG.
 *)
let rec flatten_cmd cmd =
  match cmd with
  | Seq (c1, c2) -> flatten_cmd c1 @ flatten_cmd c2
  | _ -> [ cmd ]

(* =============================================================================
 * CFG GENERATION: The Core Algorithm
 * =============================================================================
 *
 * PROBLEM: Turn a flat list of statements into a control flow graph.
 *
 * KEY DESIGN DECISION: **MAXIMAL BASIC BLOCKS**
 * -----------------------------------------------
 * We want to build the LONGEST possible sequences of straight-line code
 * before creating a new block. This is crucial for optimization:
 *   - Fewer blocks = faster dataflow analysis
 *   - Longer blocks = more opportunities for local optimization
 *
 * THE ALGORITHM (gen_stmts):
 * --------------------------
 * Input: 
 *   - builder: current CFG state
 *   - current_block_id: the "open" block we're filling
 *   - cmds: list of statements to process
 *
 * Output:
 *   - (builder', final_block_id): updated CFG + where control flow ends
 *
 * PATTERN: Process each statement in the list:
 *
 * 1. STRAIGHT-LINE (Skip, Assign):
 *    - Append to current block
 *    - Keep processing rest of list in SAME block
 *
 * 2. BRANCHING (If):
 *    - Append condition to current block (as terminator)
 *    - Create JOIN block (where paths merge)
 *    - Create THEN block, recursively process then-branch
 *    - Create ELSE block, recursively process else-branch
 *    - Connect both paths to JOIN
 *    - Continue processing rest in JOIN block
 *
 * 3. LOOPS (While):
 *    - Create HEADER block with condition
 *    - Create EXIT block (for when loop finishes)
 *    - Create BODY block, recursively process body
 *    - Add BACK EDGE: body -> header (the loop!)
 *    - Continue processing rest in EXIT block
 *
 * WHY THIS WORKS:
 * ---------------
 * - TAIL RECURSION on statement list ensures all statements processed
 * - THREADING builder through calls maintains pure functional style
 * - CURRENT BLOCK tracks where we are, enabling maximal blocks
 *
 * CRITICAL INVARIANT:
 * -------------------
 * When gen_stmts returns (builder, block_id), the block_id is the
 * block where control flow ENDS after executing all commands.
 * This allows the CALLER to connect that block to whatever comes next.
 *
 * EXAMPLE:
 * --------
 * Input: [x:=1; y:=2; if (x > 0) then z:=3 else z:=4; w:=5]
 *
 * Generated CFG:
 *   Block 0: [x:=1, y:=2, if (x>0)]
 *            |         |
 *         (true)    (false)
 *            |         |
 *   Block 1: [z:=3]  Block 2: [z:=4]
 *            |         |
 *            +----+----+
 *                 |
 *            Block 3: [w:=5]
 *
 * Notice: x:=1 and y:=2 are in the SAME block (maximal)!
 *)
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
          (* Put the 'If' stmt in the current block (as the terminator
             condition) *)
          let builder =
            append_stmt builder current_block_id (If (cond, Skip, Skip))
          in

          (* Create Join block (where paths meet) with Skip *)
          let builder, join_id = create_block builder in
          let builder = append_stmt builder join_id Skip in

          (* Process THEN path *)
          let builder, then_entry = create_block builder in
          let builder, then_end =
            gen_stmts builder then_entry (flatten_cmd then_branch)
          in
          let builder = add_edge builder current_block_id then_entry True in
          let builder = add_edge builder then_end join_id Unconditional in

          (* Process ELSE path *)
          let builder, else_entry = create_block builder in
          let builder, else_end =
            gen_stmts builder else_entry (flatten_cmd else_branch)
          in
          let builder = add_edge builder current_block_id else_entry False in
          let builder = add_edge builder else_end join_id Unconditional in

          (* Continue processing remaining commands in the JOIN block *)
          gen_stmts builder join_id rest
      (* LOOPS: Close current, Jump to Header, Recurse *)
      | While (cond, body) ->
          (* Put the 'While' condition in the current block *)
          let builder = append_stmt builder current_block_id (While (cond, Skip)) in

          (* Create Loop Exit block with Skip *)
          let builder, exit_id = create_block builder in
          let builder = append_stmt builder exit_id Skip in

          (* Process Body *)
          let builder, body_entry = create_block builder in
          let builder, body_end =
            gen_stmts builder body_entry (flatten_cmd body)
          in

          (* Wire edges *)
          let builder = add_edge builder current_block_id body_entry True in
          (* Loop matches *)
          let builder = add_edge builder current_block_id exit_id False in
          (* Loop finishes *)
          let builder = add_edge builder body_end current_block_id Unconditional in
          (* Back edge *)

          (* Continue in Exit block *)
          gen_stmts builder exit_id rest
      | Seq _ ->
          failwith "Should be flattened" (* Unreachable due to flatten_cmd *)
    )

(* =============================================================================
 * PUBLIC API: generate_cfg
 * =============================================================================
 *
 * ENTRY POINT for CFG construction.
 *
 * INPUTS:
 * -------
 * - verbose: optional logging flag (default false)
 * - Prog(_, _, body): the MiniImp program (we only care about body)
 *
 * OUTPUT:
 * -------
 * A CFG record with:
 *   - blocks: map of block_id -> block (statements)
 *   - edges: adjacency list (source -> [(target, condition)])
 *   - entry: block_id of entry point
 *   - exit: block_id of exit point
 *
 * THE ALGORITHM:
 * --------------
 * 1. Create ENTRY block with Skip (canonical starting point)
 * 2. Flatten the program body (Seq trees -> flat list)
 * 3. Call gen_stmts to build CFG from flat list
 * 4. Create EXIT block with Skip (canonical ending point)
 * 5. Connect final block to EXIT
 *
 * WHY EXPLICIT ENTRY/EXIT BLOCKS?
 * --------------------------------
 * Having explicit entry/exit blocks (even if they only contain Skip) makes
 * dataflow analysis MUCH simpler:
 *   - Entry: Clear starting point for forward analysis
 *   - Exit: Clear merge point for backward analysis
 *   - Uniformity: Every CFG has the same structure
 *   - No special cases for "program start" or "program end"
 *)

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

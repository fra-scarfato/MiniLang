open MiniImpSyntax

(* ========== CFG Data Structures ========== *)

type block_id = int

type block = {
  id: block_id;
  stmts: command list;
}

type edge_label =
  | Unconditional
  | True
  | False

module BlockMap = Map.Make(struct type t = block_id let compare = compare end)

type cfg = {
  blocks: block BlockMap.t;
  edges: (block_id * edge_label) list BlockMap.t;
  entry: block_id;
  exit: block_id;
}

(* ========== CFG Builder (Functional) ========== *)

type cfg_builder = {
  next_id: block_id;
  blocks: block BlockMap.t;
  edges: (block_id * edge_label) list BlockMap.t;
}

let create_builder () = {
  next_id = 0;
  blocks = BlockMap.empty;
  edges = BlockMap.empty;
}

let add_block builder stmts =
  let id = builder.next_id in
  let block = { id; stmts } in
  let new_builder = {
    next_id = id + 1;
    blocks = BlockMap.add id block builder.blocks;
    edges = builder.edges;
  } in
  (new_builder, id)

let add_edge builder src dst label =
  let current_edges = match BlockMap.find_opt src builder.edges with
    | Some edges -> edges
    | None -> [] 
  in
  { builder with edges = BlockMap.add src ((dst, label) :: current_edges) builder.edges }

(* ========== CFG Generation ========== *)

let rec gen_cfg_fragment builder cmd =
  match cmd with
  | Skip ->
      let (builder', id) = add_block builder [Skip] in
      (builder', id, id)

  | Assign (var, expr) ->
      let (builder', id) = add_block builder [Assign (var, expr)] in
      (builder', id, id)

  | Seq (c1, c2) ->
      let (builder, entry1, exit1) = gen_cfg_fragment builder c1 in
      let (builder, entry2, exit2) = gen_cfg_fragment builder c2 in
      let builder = add_edge builder exit1 entry2 Unconditional in
      (builder, entry1, exit2)

  | If (cond, then_branch, else_branch) ->
      let (builder, test_id) = add_block builder [If (cond, Skip, Skip)] in
      let (builder, then_entry, then_exit) = gen_cfg_fragment builder then_branch in
      let (builder, else_entry, else_exit) = gen_cfg_fragment builder else_branch in
      let (builder, join_id) = add_block builder [Skip] in
      
      let builder = add_edge builder test_id then_entry True in
      let builder = add_edge builder test_id else_entry False in
      let builder = add_edge builder then_exit join_id Unconditional in
      let builder = add_edge builder else_exit join_id Unconditional in
      
      (builder, test_id, join_id)

  | While (cond, body) ->
      let (builder, test_id) = add_block builder [While (cond, Skip)] in
      let (builder, body_entry, body_exit) = gen_cfg_fragment builder body in
      let (builder, loop_exit_id) = add_block builder [Skip] in
      
      let builder = add_edge builder test_id body_entry True in
      let builder = add_edge builder test_id loop_exit_id False in
      let builder = add_edge builder body_exit test_id Unconditional in
      
      (builder, test_id, loop_exit_id)

(* ========== Public API ========== *)

let generate_cfg (Prog (_, _, body)) =
  let builder = create_builder () in
  let (builder, entry_id) = add_block builder [Skip] in
  let (builder, body_entry, body_exit) = gen_cfg_fragment builder body in
  let (builder, exit_id) = add_block builder [Skip] in
  
  let builder = add_edge builder entry_id body_entry Unconditional in
  let builder = add_edge builder body_exit exit_id Unconditional in
  
  {
    blocks = builder.blocks;
    edges = builder.edges;
    entry = entry_id;
    exit = exit_id;
  }

(* ========== Utility Functions ========== *)

let get_successors (cfg : cfg) block_id =
  match BlockMap.find_opt block_id cfg.edges with
  | Some succs -> succs
  | None -> []

let get_predecessors (cfg : cfg) block_id =
  BlockMap.fold (fun src succs acc ->
    if List.exists (fun (dst, _) -> dst = block_id) succs then
      src :: acc
    else
      acc
  ) cfg.edges []

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

let print_cfg (cfg : cfg) =
  Printf.printf "--- CFG ---\nEntry: %d | Exit: %d | Blocks: %d\n"
    cfg.entry cfg.exit (BlockMap.cardinal cfg.blocks);
  
  BlockMap.iter (fun id block ->
    let stmts_str = 
      block.stmts 
      |> List.map string_of_command_short 
      |> String.concat "; " in
    Printf.printf "\nBlock %d:\n  Stmts: %s\n" id stmts_str;
    
    let succs = get_successors (cfg : cfg) id in
    if succs <> [] then
      List.iter (fun (succ_id, label) ->
        Printf.printf "  --> %d %s\n" succ_id (string_of_edge_label label)
      ) succs
    else
      Printf.printf "  (no successors)\n"
  ) cfg.blocks;
  Printf.printf "-----------\n"
open MiniImpCFG

(* Helper functions *)
let new_id =
  let node_counter = ref 0 in
  fun () ->
    (* Dereferencing the pointer *)
    let id = !node_counter in
    (* Increase the reference *)
    incr node_counter;
    id

let create_block ?(commands = []) ?(term = End) () =
  { id = new_id (); commands; term }

let append_command block cmd = { block with commands = block.commands @ cmd }
let set_terminator block term = { block with term }
let add_block cfg node = { cfg with nodes = KeyMap.add node.id node cfg.nodes }
let add_blocks cfg blocks = List.fold_left add_block cfg blocks

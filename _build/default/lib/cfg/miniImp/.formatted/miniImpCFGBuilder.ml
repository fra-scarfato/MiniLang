open MiniImpCFG
open MiniImpCFGUtils
open MiniImpTypes

let build_cfg prog =
  let empty_cfg = { nodes = KeyMap.empty; entry = 0; exit = 0 } in

  let rec process_command cfg curr_block = function
    | (Skip | Assign _) as cmd ->
        let curr_block = append_command curr_block cmd in
        (add_block cfg curr_block, curr_block)
    | Seq (c1, c2) ->
        let cfg, block = process_command cfg curr_block c1 in
        process_command cfg block c2
    | If (cond, then_cmd, else_cmd) ->
        let then_block = create_block () in
        let else_block = create_block () in
        let end_block = create_block () in

        let curr_block = append_command curr_block (If (cond, Skip, Skip)) in
        let curr_block =
          set_terminator curr_block (CondJump (then_block.id, else_block.id))
        in

        let cfg, then_block = process_command cfg then_block then_cmd in
        let cfg, else_block = process_command cfg else_block else_cmd in

        let then_block = set_terminator then_block (Jump end_block.id) in
        let else_block = set_terminator else_block (Jump end_block.id) in
        let final_cfg =
          add_blocks cfg [ curr_block; then_block; else_block; end_block ]
        in
        (final_cfg, end_block)
    | While (cond, body) ->
        let body_block = create_block () in
        let end_block = create_block () in

        let curr_block =
          {
            curr_block with
            commands = curr_block.commands @ [ While (cond, Skip) ];
            term = CondJump (body_block.id, end_block.id);
          }
        in

        let cfg, body_block = process_command cfg body_block body in
        let body_block = set_terminator body_block (Jump curr_block.id) in
        let final_cfg = add_blocks cfg [ curr_block; body_block; end_block ] in
        (final_cfg, end_block)
  in
  let starting_node = create_block () in
  let cfg_to_build =
    {
      empty_cfg with
      nodes = KeyMap.add starting_node.id starting_node empty_cfg.nodes;
    }
  in
  let cfg, final_node = process_command cfg_to_build starting_node prog in
  { cfg with entry = starting_node.id; exit = final_node.id }

let build_cfg_from_program program =
  match program with Prog (_, _, cmd) -> build_cfg cmd

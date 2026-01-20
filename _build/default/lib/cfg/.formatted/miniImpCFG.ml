(* MiniImpCFG.ml *)

(* Open the modules that define the types used in the CFG construction *)
open MiniImpTypes
open MiniImpBlock

(* The MiniImpCFG module encapsulates the control flow graph (CFG) construction
   and printing functions. *)
module MiniImpCFG = struct
  (** [BlockMap] is a mapping from block IDs (integers) to blocks. *)
  module BlockMap = Map.Make (struct
    type t = int

    let compare = compare
  end)

  type cfg = { nodes : MiniImpBlock.block BlockMap.t; entry : int; exit : int }
  (** The type [cfg] represents a control flow graph. It contains:
      - [nodes]: a mapping from block IDs to the corresponding block.
      - [entry]: the ID of the entry block.
      - [exit]: the ID of the exit block. *)

  (** [empty_cfg] is an empty CFG with no nodes and default entry/exit set to 0.
  *)
  let empty_cfg = { nodes = BlockMap.empty; entry = 0; exit = 0 }

  (** [add_block cfg block] returns a new CFG with [block] added to [cfg.nodes].
      @param cfg The current CFG.
      @param block The block to add.
      @return A new CFG with the block inserted into the map. *)
  let add_block cfg (block : MiniImpBlock.block) =
    { cfg with nodes = BlockMap.add block.id block cfg.nodes }

  (** [add_blocks cfg blocks] returns a new CFG with all blocks from [blocks]
      added to [cfg].
      @param cfg The current CFG.
      @param blocks A list of blocks to add.
      @return A new CFG with the blocks added. *)
  let add_blocks cfg blocks = List.fold_left add_block cfg blocks

  (** [string_of_cfg cfg] converts the entire CFG into a human-readable string.
      It folds over all blocks in [cfg.nodes] and concatenates their string
      representations.
      @param cfg The CFG to convert.
      @return A string representation of the CFG. *)
  let string_of_cfg (cfg : cfg) : string =
    BlockMap.fold
      (fun block_id block acc ->
        acc ^ MiniImpBlock.string_of_block block_id block ^ "\n"
      )
      cfg.nodes ""

  (** [process_command cfg curr_block cmd] recursively processes a command [cmd]
      and constructs the CFG.

      - For simple commands ([Skip] and [Assign _]), the command is appended to
        the [curr_block].
      - For a sequence ([Seq (c1, c2)]), it processes [c1] first then [c2] in
        the same block.
      - For [If] statements, it creates new blocks for the then-branch,
        else-branch, and a merge block, finalizing the current block before
        branching.
      - For [While] loops, it creates a block for the loop body and an end
        block, finalizing the current block before processing the loop body.

      @param cfg The current CFG.
      @param curr_block The current block being built.
      @param cmd The command to process.
      @return
        A tuple of the updated CFG and the current block after processing [cmd].
  *)
  let rec process_command cfg (curr_block : MiniImpBlock.block) = function
    | (Skip | Assign _) as cmd ->
        (* Append simple commands to the current block *)
        let curr_block = MiniImpBlock.append_command curr_block cmd in
        (cfg, curr_block)
    | Seq (c1, c2) ->
        (* Process the first command, then the second command in the resulting
           block *)
        let cfg, block = process_command cfg curr_block c1 in
        process_command cfg block c2
    | If (cond, then_cmd, else_cmd) ->
        (* For an if statement, create separate blocks for each branch and an
           end block *)
        let then_block = MiniImpBlock.create_block () in
        let else_block = MiniImpBlock.create_block () in
        let end_block = MiniImpBlock.create_block () in
        (* Append a placeholder if-command to the current block *)
        let curr_block =
          MiniImpBlock.append_command curr_block (If (cond, Skip, Skip))
        in
        (* Set the terminator of the current block to a conditional jump
           directing control flow to the then and else blocks *)
        let curr_block =
          MiniImpBlock.set_terminator curr_block
            (CondJump (then_block.id, else_block.id))
        in
        (* Finalize the current block before branching *)
        let curr_block = MiniImpBlock.finalize_block curr_block in
        (* Process the then-branch and else-branch commands *)
        let cfg, then_block = process_command cfg then_block then_cmd in
        let cfg, else_block = process_command cfg else_block else_cmd in
        (* Set the terminator of the then and else blocks to jump to the end
           block *)
        let then_block =
          MiniImpBlock.set_terminator then_block (Jump end_block.id)
        in
        let else_block =
          MiniImpBlock.set_terminator else_block (Jump end_block.id)
        in
        (* Add all the blocks created to the CFG *)
        let cfg =
          add_blocks cfg [ curr_block; then_block; else_block; end_block ]
        in
        (cfg, end_block)
    | While (cond, body) ->
        (* For a while loop, create blocks for the loop body and the loop
           exit *)
        let body_block = MiniImpBlock.create_block () in
        let end_block = MiniImpBlock.create_block () in
        (* Append a placeholder while-command to the current block *)
        let curr_block =
          MiniImpBlock.append_command curr_block (While (cond, Skip))
        in
        (* Set the terminator of the current block to conditionally jump to the
           loop body or exit *)
        let curr_block =
          MiniImpBlock.set_terminator curr_block
            (CondJump (body_block.id, end_block.id))
        in
        (* Finalize the current block before entering the loop body *)
        let curr_block = MiniImpBlock.finalize_block curr_block in
        (* Process the loop body command *)
        let cfg, body_block = process_command cfg body_block body in
        (* Set the terminator of the loop body to jump back to the current block
           (loop back) *)
        let body_block =
          MiniImpBlock.set_terminator body_block (Jump curr_block.id)
        in
        (* Add the current block, loop body, and exit block to the CFG *)
        let cfg = add_blocks cfg [ curr_block; body_block; end_block ] in
        (cfg, end_block)

  (** [build_cfg prog] builds a CFG from a given program command [prog]. It
      creates the starting block, processes the command to build the CFG,
      finalizes the last block, and sets the entry and exit block IDs.

      @param prog The program command from which to build the CFG.
      @return The constructed CFG with proper entry and exit block IDs. *)
  let build_cfg prog =
    (* Create the starting block *)
    let starting_block = MiniImpBlock.create_block () in
    (* Initialize the CFG with the starting block *)
    let cfg =
      {
        empty_cfg with
        nodes = BlockMap.add starting_block.id starting_block empty_cfg.nodes;
      }
    in
    (* Process the program command, updating the CFG and obtaining the final
       block *)
    let cfg, final_block = process_command cfg starting_block prog in
    (* Finalize the final block to obtain its completed command list *)
    let final_block = MiniImpBlock.finalize_block final_block in
    (* Add the finalized block to the CFG *)
    let cfg = add_block cfg final_block in
    (* Return the CFG with the correct entry and exit block IDs *)
    { cfg with entry = starting_block.id; exit = final_block.id }

  (** [build_cfg_from_program prog] extracts the command from a program and
      builds a CFG.
      @param prog A program of the form [Prog (_, _, cmd)].
      @return The CFG constructed from the program command. *)
  let build_cfg_from_program = function Prog (_, _, cmd) -> build_cfg cmd
end

open MiniImpTypes
open MiniImpEval

(** This module defines blocks used in the MiniImp interpreter. A block consists
    of a unique identifier, a list of commands, and a terminator instruction.
    Commands are accumulated using a difference list style (by prepending) for
    efficiency and then finalized by reversing the list to restore the correct
    order. *)
module MiniImpBlock = struct
  (** The [term] type represents the terminator instruction of a block. It can
      be:
      - [End]: indicating no further instructions (exit).
      - [Jump target]: an unconditional jump to the block with identifier
        [target].
      - [CondJump (t, f)]: a conditional jump where [t] is the target if the
        condition is true, and [f] is the target if false. *)
  type term = End | Jump of int | CondJump of int * int

  type block = {
    id : int;
    commands : command list;  (** Finalized list of commands. *)
    term : term;  (** Terminator instruction for control flow. *)
  }
  (** A [block] represents a basic block in the control flow graph. It contains:
      - [id]: a unique identifier for the block.
      - [commands]: a list of commands (finalized in the proper order).
      - [term]: the terminator instruction for the block. *)

  (** [new_id] generates a unique identifier for blocks. It uses a locally
      scoped mutable counter. *)
  let new_id =
    let counter = ref 0 in
    fun () ->
      let id = !counter in
      incr counter;
      id

  (** [create_block ?(commands=[]) ?(term=End) ()] creates a new block.
      @param commands An optional list of commands (default is the empty list).
      @param term An optional terminator (default is [End]).
      @return A new block with a unique id. *)
  let create_block ?(commands = []) ?(term = End) () =
    { id = new_id (); commands; term }

  (** [append_command block cmd] returns a new block with [cmd] prepended to the
      commands list. This technique uses a difference list style for efficiency.
  *)
  let append_command block cmd = { block with commands = cmd :: block.commands }

  (** [finalize_block block] returns a new block with the commands list
      reversed, thus restoring the original order. *)
  let finalize_block block = { block with commands = List.rev block.commands }

  (** [set_terminator block term] returns a new block with its terminator set to
      [term]. *)
  let set_terminator block term = { block with term }

  (** [get_id block] returns the unique identifier of the block. *)
  let get_id block = block.id

  (* ------------------------ Printing Functions ------------------------- *)

  (** [string_of_terminator term] returns a string representation of [term].
      @param term The terminator to be converted to string. *)
  let string_of_terminator (term : term) : string =
    match term with
    | Jump target -> Printf.sprintf "    jump -> Block %d" target
    | CondJump (t, f) ->
        Printf.sprintf "    true → Block %d\n    false → Block %d" t f
    | End -> "    exit"

  (** [string_of_block block_id block] returns a string representation of
      [block]. It includes the block identifier, its list of commands (each
      indented), and its terminator.
      @param block_id The identifier of the block (usually [block.id]).
      @param block The block to be converted to a string. *)
  let string_of_block (block_id : int) (block : block) : string =
    let commands_str =
      block.commands |> List.map string_of_command
      |> List.map (fun s -> "    " ^ s) (* Indent each command *)
      |> String.concat "\n"
    in
    let terminator_str = string_of_terminator block.term in
    Printf.sprintf "Block %d:\n  Commands:\n%s\n  Terminator:\n%s\n" block_id
      commands_str terminator_str
end

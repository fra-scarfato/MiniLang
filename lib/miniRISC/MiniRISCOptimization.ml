open MiniRISCSyntax

(* ========== Peephole Optimization ========== *)

(* Remove redundant instructions - pure functional list transformation *)
let rec peephole = function
  | [] -> []
  (* Remove self-copy: Copy r1, r1 -> remove *)
  | UnaryOp (Copy, r1, r2) :: rest when r1 = r2 -> peephole rest
  (* Fold consecutive copies: Copy r1, r2; Copy r2, r3 -> Copy r1, r3 *)
  | UnaryOp (Copy, r1, r2) :: UnaryOp (Copy, r2', r3) :: rest when r2 = r2' ->
      peephole (UnaryOp (Copy, r1, r3) :: rest)
  (* Remove Nop *)
  | Nop :: rest -> peephole rest
  (* LoadI followed by copy: LoadI n, r1; Copy r1, r2 -> LoadI n, r2 *)
  (* ATTENTION: This optimization assumes no side effects and that r1 is not used elsewhere *)
  | LoadI (n, r1) :: UnaryOp (Copy, r1', r2) :: rest when r1 = r1' ->
      peephole (LoadI (n, r2) :: rest)
  (* Keep everything else *)
  | instr :: rest -> instr :: peephole rest

(* Apply peephole optimization to command list *)
let optimize_commands cmds = peephole cmds

(* Apply optimization to all blocks in a CFG *)
let optimize_cfg (cfg : MiniRISCCFG.risc_cfg) : MiniRISCCFG.risc_cfg =
  let open MiniRISCCFG in
  let optimized_blocks =
    BlockMap.map
      (fun block -> { block with commands = optimize_commands block.commands })
      cfg.blocks
  in
  { cfg with blocks = optimized_blocks }

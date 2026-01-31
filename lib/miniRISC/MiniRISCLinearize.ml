open MiniRISCSyntax
open MiniRISCCFG

(* =============================================================================
 * MINIRIS CFG LINEARIZATION: From Graph to Flat Code
 * =============================================================================
 *
 * This is the final compilation step: converting the optimized CFG back into
 * a flat sequence of labeled instructions. It's conceptually simple but has
 * important implications for code quality.
 *
 * THE TASK:
 * ---------
 * Input: A CFG where blocks can be in any order, connected by jumps
 * Output: A linear sequence of instructions with labels
 *
 * EXAMPLE CFG:
 *   Block 3 --jumps to--> Block 1 --jumps to--> Block 2
 *
 * NAIVE LINEARIZATION (emits in ID order):
 *   L1:          # Block 1
 *     add r1 r2 => r3
 *     jump L2
 *   L2:          # Block 2  
 *     mult r3 r4 => r5
 *     jump L3
 *   L3:          # Block 3 (entry!)
 *     loadi 5 => r1
 *     jump L1
 *
 * SMART LINEARIZATION (emits in execution order):
 *   L3:          # Block 3 (entry)
 *     loadi 5 => r1
 *     # fall through (no explicit jump needed!)
 *   L1:          # Block 1
 *     add r1 r2 => r3
 *     # fall through
 *   L2:          # Block 2
 *     mult r3 r4 => r5
 *
 * WHY ORDER MATTERS:
 * ------------------
 * 1. FALL-THROUGH OPTIMIZATION: If block A jumps to block B, and B immediately
 *    follows A in the linear code, we can ELIMINATE the jump instruction.
 *    Just let execution "fall through" to the next block.
 *
 * 2. BRANCH PREDICTION: Modern CPUs predict that forward branches are not
 *    taken, backward branches are taken (loop pattern). Ordering code to
 *    match this improves performance.
 *
 * 3. CACHE LOCALITY: Blocks executed together should be near each other in
 *    memory (instruction cache benefits).
 *
 * OUR STRATEGY: SIMPLE ID-ORDER
 * -----------------------------
 * We currently emit blocks in sorted ID order. This is simple and predictable
 * but not optimal. A better approach would:
 *   - Use execution frequency (hot blocks first)
 *   - Maximize fall-through opportunities
 *   - Respect loop structure (keep loop bodies together)
 *
 * For an educational compiler, simple is good enough. Production compilers
 * spend significant effort on code layout optimization.
 *)

(* ========== Linearization ========== *)

(* A RISC program is a list of labeled blocks *)
type labeled_instruction = LabelDef of label | Instruction of command
type risc_program = labeled_instruction list

(* ========== Printing ========== *)

let string_of_labeled_instruction = function
  | LabelDef (Label l) -> l ^ ":"
  | Instruction cmd -> "  " ^ MiniRISCUtils.string_of_command cmd

let print_risc_program prog =
  List.iter
    (fun instr -> Printf.printf "%s\n" (string_of_labeled_instruction instr))
    prog

(* Logging utility *)
let log_verbose verbose fmt =
  Printf.ksprintf (fun s -> if verbose then print_endline s else ()) fmt

(* -----------------------------------------------------------------------------
 * linearize_cfg: Convert CFG to Sequential Instruction List
 * -----------------------------------------------------------------------------
 *
 * Takes a CFG and produces a flat list of labeled instructions.
 *
 * ORDERING STRATEGY:
 * Currently emits blocks in ID order (sorted by block.id). This is simple
 * and predictable but not optimal for performance.
 *
 * BETTER STRATEGIES (not implemented):
 * - Execution frequency order (hot blocks first)
 * - Maximize fall-through opportunities (reduce jumps)
 * - Loop-aware ordering (keep loop bodies together)
 *
 * ENTRY BLOCK SPECIAL CASE:
 * The entry block gets labeled "main" instead of its generated label.
 * This is the standard entry point for execution.
 *
 * OUTPUT FORMAT:
 * - LabelDef: Block entry points (L1:, L2:, main:)
 * - Instruction: Actual commands (indented with "  ")
 *)
let linearize_cfg ?(verbose = false) (cfg : risc_cfg) : risc_program =
  log_verbose verbose "\n=== CFG Linearization ===";

  (* Traverse blocks in ID order (could use other orderings) *)
  let blocks_list =
    BlockMap.fold (fun _ block acc -> block :: acc) cfg.blocks []
    |> List.sort (fun b1 b2 -> compare b1.id b2.id)
  in

  (* Generate code for each block *)
  let rec emit_blocks = function
    | [] -> []
    | block :: rest ->
        (* Use "main" label for entry block, otherwise use block's label *)
        let label =
          if block.id = cfg.entry then Label "main" else block.label
        in

        let label_def = [ LabelDef label ] in
        let instrs = List.map (fun cmd -> Instruction cmd) block.commands in
        let term =
          match block.terminator with Some t -> [ Instruction t ] | None -> []
        in

        label_def @ instrs @ term @ emit_blocks rest
  in

  let prog = emit_blocks blocks_list in

  if verbose then (
    log_verbose verbose "Generated %d instructions" (List.length prog);
    log_verbose verbose "\n--- Linear Code ---";
    print_risc_program prog
  );

  prog

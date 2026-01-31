# Instruction-Level Liveness Analysis - Implementation

## Overview

Integrated instruction-level liveness analysis into the `LiveVariables` module for precise register coalescing.

## Architecture

### Single-Pass, Two-Level Analysis

```
┌─────────────────────────────────────────┐
│  LiveVariables.analyze()                │
│                                         │
│  Step 1: Block-Level (Iterative)       │
│  ├─ Compute IN/OUT for each block      │
│  ├─ Fixpoint iteration across CFG      │
│  └─ Result: block_in, block_out maps   │
│                                         │
│  Step 2: Instruction-Level (Single pass)│
│  ├─ For each block:                    │
│  │  ├─ Start with block_out            │
│  │  └─ Walk backward through instrs    │
│  └─ Result: instr_after map            │
│                                         │
│  Output: { block_in, block_out,        │
│            instr_after }                │
└─────────────────────────────────────────┘
```

### Pure Functional Implementation

**Data Structures:**
```ocaml
type instr_point = int * int  (* (block_id, instruction_index) *)

module InstrPointMap = Map.Make(...)

type analysis_result = {
  block_in : RegisterSet.t BlockMap.t;     (* Block-level: entry *)
  block_out : RegisterSet.t BlockMap.t;    (* Block-level: exit *)
  instr_after : RegisterSet.t InstrPointMap.t;  (* Instruction-level *)
}
```

**Key Functions:**
1. `compute_local_info` - Computes upward-exposed uses and killed defs per block
2. `compute_instruction_level_liveness` - Refines liveness within each block
3. `analyze` - Main entry point combining both levels

## Algorithm Details

### Block-Level (Step 1)

Standard backward dataflow fixpoint iteration:

```
Initialization: IN[B] = ∅ for all blocks

Iterate until fixpoint:
  For each block B:
    OUT[B] = ∪ IN[S] for all successors S
    IN[B] = UpwardExposed[B] ∪ (OUT[B] - Killed[B])
```

### Instruction-Level (Step 2)

For each block, single backward pass:

```
Start: live_current = OUT[block]

For instr_idx from (num_instrs - 1) down to 0:
  Record: instr_after[(block_id, instr_idx)] = live_current
  
  live_before = (live_current - DEF[instr]) ∪ USE[instr]
  
  live_current = live_before
```

**No iteration needed** - straight backward propagation!

## Integration with Register Allocation

### Before (Edge-Based Coalescing)

```ocaml
(* Old approach - CFG edges only *)
let live_ranges = 
  BlockMap.fold (fun src_id -> 
    List.fold_left (fun dst_id ->
      (* Add edge (src, dst) to live ranges *)
    )
  )
```

**Problem:** All instructions in a block share the same edge, so:
- `r1, r2, r3` in sequential assignments appear to interfere
- 0 registers merged in test_register_pressure_2

### After (Instruction-Based Coalescing)

```ocaml
(* New approach - instruction points *)
let live_ranges = compute_live_ranges_from_liveness liveness_result in

(* Each register has precise point set *)
(* r1 live at {(0,0), (0,1)} *)
(* r2 live at {(0,1), (0,2)} *)
(* r3 live at {(0,2), (0,3)} *)

(* Check interference: *)
ranges_interfere r1_range r2_range  (* Some overlap at (0,1) *)
ranges_interfere r1_range r3_range  (* No overlap - can merge! *)
```

**Result:** Sequential variables with non-overlapping lifetimes can merge!

## Example: test_register_pressure_2.minimp

### Code
```
a = x + 1;   // Instr 0: r1 = r_in + 1
b = a + 2;   // Instr 1: r2 = r1 + 2
c = b + 3;   // Instr 2: r3 = r2 + 3
...
```

### Liveness at Instruction Points

```
Point (0, 0): {r_in}          (before instr 0)
Point (0, 1): {r1}            (after instr 0, r_in dead)
Point (0, 2): {r2}            (after instr 1, r1 dead)  
Point (0, 3): {r3}            (after instr 2, r2 dead)
...
```

### Live Ranges

```
r1: {(0,1)}
r2: {(0,2)}
r3: {(0,3)}
...
```

**All disjoint!** → Can merge into 1-2 registers instead of 16!

## Expected Improvements

### Before Instruction-Level
```
Virtual registers: 16
Merged: 0
Spilled (target=6): 14 registers
Instructions: ~78 (many load/store)
```

### After Instruction-Level
```
Virtual registers: 16
Merged: 12-14
Remaining: 2-4 registers
Spilled (target=6): 0 registers!
Instructions: ~18 (no spilling overhead)
```

**~75% reduction in code size for sequential patterns!**

## Performance

- **Block-level:** O(iterations × blocks × edges) - same as before
- **Instruction-level:** O(blocks × instructions) - single pass per block
- **Total overhead:** Negligible - just one extra backward walk

## Future Enhancements

1. **Copy Coalescing:** Detect `r2 = r1` patterns and merge even if slight overlap
2. **Live Range Splitting:** Break long ranges to reduce spilling
3. **Priority-Based Merging:** Merge high-frequency registers first
4. **Spill Cost Analysis:** Use instruction-level info for smarter spilling decisions

## Testing

Run the test suite to verify:
```bash
# Should now show significant register merging
dune exec MiniImpCompiler -- -O -v 6 test_ex/test_register_pressure_2.minimp out.risc

# Expected output:
# Total registers merged: 12-14
# Spilling required: NO
```

## Pure Functional Benefits

✓ **No mutable state** - all maps are immutable  
✓ **Composable** - easy to chain analyses  
✓ **Testable** - deterministic results  
✓ **Maintainable** - clear data flow  
✓ **Correct** - no aliasing bugs  

The implementation maintains OCaml's functional programming style while achieving optimal performance!

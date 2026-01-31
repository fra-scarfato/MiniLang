# MiniImp to MiniRISC Compiler - Complete Documentation

A comprehensive compiler from MiniImp (a simple imperative language) to MiniRISC (a RISC-like assembly language), with register allocation, optimization, and safety analysis.

---

## Table of Contents

1. [Overview](#overview)
2. [Language Design](#language-design)
3. [Architecture](#architecture)
4. [Compilation Pipeline](#compilation-pipeline)
5. [Control Flow Graph Construction](#control-flow-graph-construction)
6. [Translation Strategy](#translation-strategy)
7. [Register Allocation](#register-allocation)
8. [Optimization](#optimization)
9. [Dataflow Analysis](#dataflow-analysis)
10. [Design Decisions](#design-decisions)
11. [Usage](#usage)

---

## Overview

This compiler translates programs from **MiniImp** (a minimal imperative language with variables, conditionals, and loops) to **MiniRISC** (a register-based assembly language), performing optimizations and register allocation along the way.

### Key Features

- **Register Allocation**: Maps unlimited virtual registers to a fixed number of physical registers (minimum 4)
- **Register Coalescing**: Merges non-interfering registers to reduce pressure
- **Instruction-Level Liveness**: Fine-grained analysis for precise optimization
- **Safety Checking**: Detects uninitialized variable usage
- **Optimization**: Algebraic simplification, peephole optimization, dead store elimination
- **Pure Functional**: No mutable state, clean functional style throughout

---

## Language Design

### MiniImp: The Source Language

**Design Philosophy: MINIMAL BUT COMPLETE**

MiniImp has exactly what you need for imperative programming:
- **Variables**: Mutable state (integers only)
- **Arithmetic**: Addition, subtraction, multiplication
- **Conditionals**: If-then-else
- **Loops**: While loops
- **Booleans**: Comparisons and logical operations

**What it intentionally DOESN'T have:**
- Functions/procedures (would need stack management)
- Arrays/pointers (would need heap and addressing)
- Multiple types (would need type checking)
- I/O statements (handled by program wrapper)

**The Expression Hierarchy:**

We separate expressions into TWO distinct types:

1. **Operations** (arithmetic expressions) - produce integers
   - Example: `x + 5`, `y * 2`

2. **Booleans** (logical expressions) - produce true/false
   - Example: `x < 10`, `not done`

This separation prevents type confusion at the syntax level. You can't write `x + true` because operations only accept operations, not booleans.

**Program Structure:**

Every MiniImp program follows this template:
```
def main with input <var> output <var> as
  <command>
```

This enforces a clear I/O interface:
- One input parameter (passed via r_in register)
- One output parameter (returned via r_out register)
- No complex calling conventions needed

### MiniRISC: The Target Language

**RISC Design Philosophy:**

MiniRISC follows classic RISC principles:
- **Load-Store Architecture**: Only Load/Store access memory
- **Simple Instructions**: Each operation is atomic and predictable
- **Register-Based**: All computation happens in registers
- **Three-Address Code**: Operations have explicit source and destination

**Instruction Set:**

```
copy r1 => r2          # Register copy
loadi 42 => r1         # Load immediate constant
load r1 => r2          # Load from memory at address in r1
store r1 => r2         # Store r1 to memory at address in r2
add r1 r2 => r3        # r3 = r1 + r2
sub r1 r2 => r3        # r3 = r1 - r2
mult r1 r2 => r3       # r3 = r1 * r2
branch r1 => L1, L2    # If r1 is true, jump to L1, else L2
jump => L1             # Unconditional jump
halt                   # Stop execution
```

**Why These Instructions?**

Each instruction represents a single, atomic operation that:
1. Takes constant time (predictable performance)
2. Has clear data dependencies (easy to analyze)
3. Maps naturally to real CPU instructions

---

## Architecture

### Module Organization

#### Source Language Modules
- **MiniImpSyntax**: AST definitions for MiniImp (expressions, commands, programs)
- **MiniImpParser**: LR(1) parser built with Menhir (handles precedence, associativity)
- **MiniImpLexer**: Lexical analyzer built with OCamllex (tokenizes source code)
- **MiniImpEval**: Reference interpreter (defines ground-truth semantics)
- **MiniImpCFG**: Control Flow Graph construction from AST

#### Target Language Modules
- **MiniRISCSyntax**: AST definitions for MiniRISC instructions
- **MiniRISCUtils**: Utilities (register operations, string conversions, set operations)
- **MiniRISCCFG**: Control Flow Graph representation for RISC code
- **MiniRISCLinearize**: Converts CFG back to sequential instruction list

#### Translation & Optimization Modules
- **MiniRISCTranslation**: MiniImp AST → MiniRISC CFG (with unlimited virtual registers)
- **MiniRISCDataflow**: Liveness and definite variables analysis
- **MiniRISCAllocation**: Register allocation, coalescing, and spilling
- **MiniRISCOptimization**: Peephole optimizations (unused in current pipeline)

#### Main Compiler
- **MiniImpCompiler**: Command-line interface, orchestrates entire pipeline

---

## Compilation Pipeline

The complete compilation process follows these phases:

```
┌─────────────────────────────────────────────────────────────┐
│                    MINIMP SOURCE CODE                       │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  PHASE 1: LEXING & PARSING     │
        │  - Tokenize source text        │
        │  - Build Abstract Syntax Tree  │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │  PHASE 2: MINIIMP CFG          │
        │  - Flatten nested Seq trees    │
        │  - Build maximal basic blocks  │
        │  - Connect with control edges  │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │  PHASE 3: TRANSLATION          │
        │  - Map variables to registers  │
        │  - Translate expressions       │
        │  - Generate MiniRISC CFG       │
        │  - Unlimited virtual registers │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │  PHASE 4: SAFETY CHECK         │
        │  (optional, with -s flag)      │
        │  - Definite variables analysis │
        │  - Detect uninitialized usage  │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │  PHASE 5: LIVENESS ANALYSIS    │
        │  - Backward MAY analysis       │
        │  - Instruction-level precision │
        │  - For optimization & coalescing│
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │  PHASE 6: REGISTER COALESCING  │
        │  (optional, with -O flag)      │
        │  - Merge non-interfering regs  │
        │  - Reduce register pressure    │
        │  - Conservative for I/O regs   │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │  PHASE 7: REGISTER ALLOCATION  │
        │  - Frequency-based allocation  │
        │  - Spill low-frequency regs    │
        │  - Insert load/store sequences │
        │  - Dead store elimination      │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │  PHASE 8: LINEARIZATION        │
        │  - Topological sort of CFG     │
        │  - Generate labels for blocks  │
        │  - Emit sequential code        │
        └────────────┬───────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   MINIRICS ASSEMBLY CODE                    │
└─────────────────────────────────────────────────────────────┘
```

**Key Points:**
- Phases 1-3 are always executed
- Phase 4 (safety) is optional (enable with `-s`)
- Phase 5 (liveness) is always run if optimization is enabled
- Phase 6 (coalescing) is optional (enable with `-O`)
- Phase 7 (allocation) is always executed
- Phase 8 (linearization) produces the final output

---

## Control Flow Graph Construction

### The Problem: Nested Sequences

The parser produces deeply nested `Seq` structures:
```
Seq(s1, Seq(s2, Seq(s3, Seq(s4, Seq(s5, ...)))))
```

This is natural for recursive parsing but awkward for CFG construction.
We want a **flat list**: `[s1; s2; s3; s4; s5]`

### Our Strategy: "Flatten & Accumulate"

**Decision: Single-Pass Construction with Maximal Basic Blocks**

We rejected a two-phase "naive generation + simplification" approach in favor of building optimal blocks immediately.

#### Comparison of Approaches

| **Naive + Merge** | **Flatten & Accumulate (Chosen)** |
|-------------------|-----------------------------------|
| Generate one block per statement | Flatten Seq trees to lists first |
| Run graph algorithm to merge chains | Accumulate statements into current block |
| O(n²) worst-case complexity | O(n) linear complexity |
| Risk of losing labels during merge | Labels only on block boundaries |
| Produces fragmented CFG initially | Produces maximal blocks immediately |

**Why Flatten-First?**

1. **EASIER ITERATION**: Process statements one-by-one without recursion
2. **MAXIMAL BLOCKS**: Build longest possible sequences of straight-line code
3. **SIMPLICITY**: Separate concerns (tree traversal vs CFG building)
4. **CORRECTNESS BY CONSTRUCTION**: No need for cleanup passes

### The CFG Generation Algorithm

**Function: `gen_stmts builder current_block_id cmds`**

Takes:
- `builder`: Current CFG state
- `current_block_id`: The "open" block we're filling
- `cmds`: List of statements to process

Returns:
- `(builder', final_block_id)`: Updated CFG + where control flow ends

**Pattern Matching on Statement Types:**

1. **Straight-Line (Skip, Assign)**
   - Append to current block
   - Keep processing rest in SAME block
   - **This builds maximal blocks!**

2. **Branching (If)**
   - Append condition to current block (as terminator)
   - Create JOIN block (where paths merge)
   - Create THEN block, recursively process then-branch
   - Create ELSE block, recursively process else-branch
   - Connect both paths to JOIN
   - **Continue processing rest in JOIN block**

3. **Loops (While)**
   - Create HEADER block with condition
   - Create EXIT block (for when loop finishes)
   - Create BODY block, recursively process body
   - Add BACK EDGE: body → header (the loop!)
   - **Continue processing rest in EXIT block**

**Example:**

Input: `[x:=1; y:=2; if (x > 0) then z:=3 else z:=4; w:=5]`

Generated CFG:
```
Block 0: [x:=1, y:=2, if (x>0)]
         |              |
      (true)         (false)
         |              |
Block 1: [z:=3]    Block 2: [z:=4]
         |              |
         +------+-------+
                |
         Block 3: [w:=5]
```

Notice: `x:=1` and `y:=2` are in the **SAME** block (maximal)!

### Why Explicit Entry/Exit Blocks?

Every CFG has dedicated entry and exit blocks (even if they only contain `Skip`).

**Benefits:**
- **Clear starting point** for forward analysis
- **Clear merge point** for backward analysis
- **Uniformity**: Every CFG has the same structure
- **No special cases** for "program start" or "program end"

These blocks are like NULL terminators in C strings - a small cost that eliminates endless edge cases!

---

## Translation Strategy

### The "Compute and Copy" Approach

**Decision: Separate Calculation from Assignment**

We use a strict separation:
1. **Expressions (`trans_op`)**: Always compute into a FRESH temporary register
2. **Assignments (`trans_cmd`)**: Explicitly copy the result to the target variable

This creates extra `copy` instructions, but it's simple and avoids a critical bug.

### Why Not "Destination Passing"?

**The Bug We Avoided:**

If we passed the destination register down the expression tree, we'd get:
```
while (x > 0) {
  x := x - 1    # Overwrites x BEFORE the loop condition checks it again!
}
```

The loop header reads the old value of `x`, but the body overwrites it directly, breaking the loop condition on the next iteration.

**Our Solution:**

By forcing expressions to use fresh temporaries and then explicitly copying:
```
temp = x - 1
copy temp => x   # Explicit update, happens AFTER condition check
```

The loop header and body remain independent.

### Variable Mapping Strategy

**Decision: Virtual Registers with Pre-Seeding**

We maintain a map: `variable_name → register_name`
- `"x"` → `r5`
- `"counter"` → `r12`

**Special Cases:**
- Input variable **always** maps to `r_in`
- Output variable **always** maps to `r_out`

This ensures:
1. **Stable calling convention**: Test harness knows where to put inputs
2. **Stable output location**: Results always in `r_out`
3. **No register confusion**: I/O registers never reallocated

### Algebraic Simplification During Translation

**Decision: Optimize While You Can Still See Structure**

We perform constant folding and identity elimination during translation:

| Pattern | Action | Why |
|---------|--------|-----|
| `x + 0` | No code generated | Identity operation |
| `x * 0` | Generate `loadi 0 => r` | Constant result |
| `x * 1` | Generate `copy x => r` | Identity operation |
| `0 + x` | Generate `copy x => r` | Identity operation |

**Why Here?**

It's easier to recognize `x * 0` in the AST than after generating:
```
loadi 0 => r1
mult r2 r1 => r3
```

Early optimization reduces work for later analysis phases.

---

## Register Allocation

### The Core Problem

Our translation phase generates code with **unlimited virtual registers**: r0, r1, r2, ... r42, etc.

Real CPUs have **limited physical registers** (maybe 8-16).

We need to:
1. Decide which virtual registers get physical registers (fast path)
2. Decide which virtual registers must live in memory (slow path)
3. Insert load/store instructions to shuffle data

### Architecture: n Physical Registers

**Target Machine Configuration:**

```
┌────────────────────────────────────────────────────┐
│ r_in      │ 1 register  │ Input (never spill)      │
│ r_out     │ 1 register  │ Output (never spill)     │
│ r_a, r_b  │ 2 registers │ Swap regs for spilling   │
│ r0..r_k   │ n-4 regs    │ General-purpose          │
└────────────────────────────────────────────────────┘
Total: n physical registers
Available for variables: n - 4 registers
```

**Key Constraints:**
- **Minimum n = 4**: Need at least r_in, r_out, r_a, r_b
- **I/O registers**: Always in registers, never spilled
- **Swap registers**: Used for load/store of spilled variables

### Two-Phase Strategy

#### Phase 1: Register Coalescing (Optional, with `-O`)

**Goal**: Merge virtual registers that never interfere

**Algorithm:**
1. Compute live ranges (instruction-level precision)
2. For each pair of registers, check if ranges overlap
3. If disjoint, merge them (choose one representative)
4. Build renaming map: `old_register → new_register`

**Example:**
```
a = x + 1;   # r1 = r_in + 1    (r1 live after)
b = a + 2;   # r2 = r1 + 2      (r1 dead, r2 live)
c = b + 3;   # r3 = r2 + 3      (r2 dead, r3 live)
```

Live ranges:
- r1: {(0,1)}
- r2: {(0,2)}
- r3: {(0,3)}

**All disjoint!** → Merge into 1 register

**Conservative Decision: Never Merge r_in or r_out**

Both I/O registers are **excluded from merging entirely**.

| Approach | Description | Pros | Cons | Chosen? |
|----------|-------------|------|------|---------|
| Allow Merging | r_in/r_out can merge | Max optimization | Risk of conflicts | ❌ |
| Spill If Needed | Treat as normal | Flexibility | Complex fixup | ❌ |
| Pin Representative | Keep merged reg in register | Allows merging | Complex tracking | ❌ |
| Never Merge | Exclude from coalescing | Simple, clear | Misses some opts | ✅ |

**Why Conservative?**
1. Clear semantics: I/O always in designated registers
2. No edge cases: Can't have merge/spill conflicts
3. Interface stability: External harness knows where to find output
4. Simplicity: Less code, easier verification

#### Phase 2: Allocation & Spilling (Always)

**Goal**: Map remaining virtual registers to n-4 physical slots

**Algorithm:**
1. **Frequency Analysis**: Count usage of each virtual register
2. **Sort by Frequency**: Most-used first
3. **Allocate**: Top (n-4) registers get physical slots
4. **Spill**: Remaining registers go to memory

**Memory Addressing:**
- Spilled variables stored at addresses: 0x1000, 0x1001, 0x1002, ...
- Why 0x1000? Visual distinction from small constants (0, 1, 2)
- Easy to spot in output: hex = memory, decimal = constant

**Instruction Rewriting:**

For each instruction involving spilled register `r`:

**Before Use:**
```
loadi 0x1000 => r_a    # Load memory address
load r_a => r_a        # Load value from memory
```

**After Definition (if live):**
```
loadi 0x1000 => r_a    # Load memory address
store r_b => r_a       # Store value to memory
```

**Dead Store Elimination:**

If liveness analysis shows the register is NOT live after the instruction, we skip the store!

```
x := 5;     # x defined here
y := 3;     # x is dead (never used again)
# Skip: store x to memory
```

This optimization is enabled with `-O` flag.

### No Redundant Address Load Optimization

**Decision: Keep It Simple**

Each load/store reloads the memory address:
```
loadi 0x1000 => r_a    # Address
store r_b => r_a       # Store
loadi 0x1000 => r_a    # Reload address (redundant!)
load r_a => r_a        # Load
```

**Why Accept Redundancy?**

| Simple (Chosen) | Address Tracking |
|-----------------|------------------|
| Rewrite each instruction independently | Thread state through rewrite |
| Low complexity | High complexity |
| Extra `loadi` instructions | Fewer instructions |
| Easy to prove correct | Must track r_a/r_b contents |
| Simple to debug | Complex bookkeeping |

For an educational compiler focused on **correctness over performance**, the simple approach wins.

---

## Optimization

### 1. Algebraic Simplification (During Translation)

Detect identity patterns in the AST:

| Pattern | Optimization | Benefit |
|---------|--------------|---------|
| `x + 0` | No code | Removes false dependency |
| `0 + x` | `copy x` | Single instruction |
| `x * 0` | `loadi 0` | Constant result |
| `x * 1` | `copy x` | Identity |
| `1 * x` | `copy x` | Identity |

**Why During Translation?**

Easier to recognize patterns when structure is still visible in the AST.

### 2. Maximal Basic Blocks (During CFG Construction)

Build the longest possible sequences of straight-line code:
- Fewer blocks = faster dataflow analysis
- Longer blocks = more opportunities for local optimization

This is "optimization by construction" - we build the optimal structure from the start.

### 3. Register Coalescing (After Translation, Before Allocation)

Merge non-interfering registers:
- Reduces register pressure
- Fewer variables to allocate
- Fewer spills needed

**Instruction-Level Liveness:**

We use fine-grained liveness (per instruction, not per CFG edge) for better coalescing:

**Before (Edge-Based):**
```
Block contains: [r1:=..., r2:=..., r3:=...]
All three appear to interfere (same block)
Result: 0 registers merged
```

**After (Instruction-Based):**
```
Instr 0: r1 live after
Instr 1: r2 live after (r1 dead)
Instr 2: r3 live after (r2 dead)
Result: All can merge into 1 register!
```

This is a **75% reduction** in register pressure for sequential code!

### 4. Dead Store Elimination (During Allocation)

Skip stores for dead values:
```ocaml
if not (is_live_after result_reg) then
  (* Skip the store - value never read *)
else
  (* Generate store instruction *)
```

Enabled with `-O` flag.

### 5. Peephole Optimization (Not Currently Used)

Pattern-based local optimizations:
- Remove redundant copies: `copy r1 r1` → removed
- Fold consecutive copies: `copy r1 r2; copy r2 r3` → `copy r1 r3`
- Combine operations: `loadi n r1; copy r1 r2` → `loadi n r2`

These are implemented but not currently in the pipeline (can be re-enabled).

---

## Dataflow Analysis

### Overview

Dataflow analysis computes properties of programs by propagating information through the CFG.

**Two Types of Analysis:**

1. **Forward (MUST)**: Propagate from entry to exit
   - Example: Definite variables (which registers are initialized?)
   
2. **Backward (MAY)**: Propagate from exit to entry
   - Example: Live variables (which registers are needed later?)

### Definite Variables Analysis (Forward MUST)

**Purpose**: Detect uninitialized register usage

**Algorithm:**
- **Direction**: Forward (entry → exit)
- **Join Operation**: Intersection (∩)
- **Initialization**: TOP (all registers assumed defined everywhere, except entry)
- **Fixpoint**: Greatest fixpoint (iterate until shrinking stops)

**Transfer Function:**
```
OUT[block] = (IN[block] - KILL[block]) ∪ GEN[block]

where:
  GEN[block]  = registers defined in block
  KILL[block] = ∅ (definitions don't kill anything)
```

**Join at Block Entry:**
```
IN[block] = ⋂ OUT[pred] for all predecessors
            pred
```

**Why MUST (Intersection)?**

We want to know: "Is this register DEFINITELY defined?"

Only if it's defined on ALL paths can we be sure.

**Implementation:**
- Start with TOP (optimistic)
- Iterate until fixpoint
- Store both IN and OUT sets (avoid recomputation)

### Live Variables Analysis (Backward MAY)

**Purpose**: Determine which registers might be used later (for allocation and dead store elimination)

**Algorithm:**
- **Direction**: Backward (exit → entry)
- **Join Operation**: Union (∪)
- **Initialization**: BOTTOM (empty set everywhere)
- **Fixpoint**: Least fixpoint (iterate until growing stops)

**Transfer Function:**
```
IN[block] = (OUT[block] - DEF[block]) ∪ USE[block]

where:
  USE[block] = registers read before being written in block
  DEF[block] = registers written in block
```

**Join at Block Exit:**
```
OUT[block] = ⋃ IN[succ] for all successors
             succ
```

**Why MAY (Union)?**

We want to know: "Might this register be used later?"

If it's used on ANY path, we must keep it live.

### Instruction-Level Liveness

**Enhancement**: Refine liveness within blocks

Standard analysis gives us:
- `IN[block]`: Live at block entry
- `OUT[block]`: Live at block exit

Instruction-level gives us:
- `LIVE_AFTER[block, i]`: Live after instruction i

**Algorithm:**
```
Start: live = OUT[block]

For i from (num_instrs - 1) down to 0:
  LIVE_AFTER[block, i] = live
  live = (live - DEF[instr_i]) ∪ USE[instr_i]
```

**No Iteration Needed!** Straight backward propagation.

**Benefit**: Precise live ranges for coalescing

**Example:**
```
Block 0:
  Instr 0: r1 := r_in + 1    # After: {r1}
  Instr 1: r2 := r1 + 2      # After: {r2}
  Instr 2: r3 := r2 + 3      # After: {r3}
```

Live ranges:
- r1: {(0,1)}
- r2: {(0,2)}
- r3: {(0,3)}

All disjoint → can merge!

### Pure Functional Implementation

All analyses are implemented without mutable state:
- Use `Map.fold` instead of imperative loops
- Thread state through functions
- No `ref` cells or arrays

**Benefits:**
- Easier to reason about
- Better testability
- No aliasing bugs
- Composable and maintainable

---

## Design Decisions

### 1. CFG Construction: Flatten & Accumulate vs Naive + Merge

**Chosen**: Flatten & Accumulate

**Rationale**:
- O(n) complexity vs O(n²)
- Produces maximal blocks immediately
- No risk of losing labels
- "Correct by construction" philosophy

### 2. Translation: Compute & Copy vs Destination Passing

**Chosen**: Compute & Copy

**Rationale**:
- Avoids infinite loop bug (destination overwrite)
- Simpler to implement and verify
- Extra copies cleaned up by optimization
- Clear separation of concerns

### 3. Variable Model: Virtual Registers vs Memory Locations

**Chosen**: Virtual Registers

**Rationale**:
- Closer to target architecture
- Easier to analyze (no aliasing)
- Register allocation is explicit phase
- Pre-seeding ensures stable I/O interface

### 4. Register Allocation: Frequency-Based vs Graph Coloring

**Chosen**: Frequency-Based

**Rationale**:
- Simple heuristic that works well
- Easy to understand and implement
- Prioritizes hot variables naturally
- Good enough for educational compiler

### 5. I/O Registers: Allow Merging vs Never Merge

**Chosen**: Never Merge (Conservative)

**Rationale**:
- Clear semantics
- No merge/spill conflicts
- Interface stability
- Simplicity over optimization

### 6. Memory Addressing: Sequential vs Hex Base

**Chosen**: 0x1000 Base Address

**Rationale**:
- Visual distinction (hex vs decimal)
- Easy debugging (spot spills immediately)
- Matches common conventions
- No functional impact

### 7. Address Loading: Reuse vs Reload

**Chosen**: Reload Each Time

**Rationale**:
- Simpler implementation
- Easier to verify correctness
- Address load is cheap compared to memory access
- Educational compiler prioritizes clarity

### 8. Code Style: Imperative vs Pure Functional

**Chosen**: Pure Functional

**Rationale**:
- Easier reasoning about correctness
- Better testability
- No hidden mutations
- OCaml idiomatic style
- Composable and maintainable

### 9. Optimization Strategy: Early vs Late

**Chosen**: Early Integration (During Translation)

**Rationale**:
- Recognize patterns while structure visible
- Reduces work for later phases
- Removes false dependencies early
- Simplify before you analyze

### 10. Dead Code Elimination: Include vs Remove

**Chosen**: Removed from Pipeline

**Rationale**:
- Correctness concerns with dataflow
- Minimal benefit (algebraic simplification covers most cases)
- Added complexity conflicts with pure functional goal

---

## Usage

### Basic Command Format

```bash
MiniImpCompiler [OPTIONS] <num_registers> <input.minimp> <output.risc>
```

### Arguments

- `<num_registers>`: Number of target physical registers (minimum 4)
- `<input.minimp>`: Input MiniImp source file
- `<output.risc>`: Output MiniRISC assembly file

### Options

- `-s, --safety`: Enable safety check (definite variables analysis)
- `-O, --optimize`: Enable optimization (coalescing + dead store elimination)
- `-v, --verbose`: Verbose output (show CFG, analysis results, statistics)
- `-h, --help`: Display help message

### Examples

**Basic compilation (8 registers, no optimization):**
```bash
dune exec MiniImpCompiler -- 8 program.minimp output.risc
```

**With optimization:**
```bash
dune exec MiniImpCompiler -- -O 8 program.minimp output.risc
```

**With safety checking:**
```bash
dune exec MiniImpCompiler -- -s 8 program.minimp output.risc
```

**Full features (safety + optimization + verbose):**
```bash
dune exec MiniImpCompiler -- -s -O -v 6 program.minimp output.risc
```

**Minimum registers (4):**
```bash
dune exec MiniImpCompiler -- 4 program.minimp output.risc
```

**Large register file (16):**
```bash
dune exec MiniImpCompiler -- -O 16 program.minimp output.risc
```

### Verbose Output Example

```
=== MiniImp CFG Generation ===
Generated 8 blocks

=== Translation to MiniRISC ===
Generated CFG with unlimited virtual registers
Total registers allocated: 24

=== Safety Check ===
All registers are properly initialized ✓

=== Liveness Analysis ===
Computing instruction-level liveness...
Fixed point reached in 3 iterations

=== STEP 1: REGISTER MERGING (COALESCING) ===
  r2 -> r1
  r5 -> r3
  r7 -> r6
Total registers merged: 3
Note: r_in and r_out are never merged

=== STEP 2: ALLOCATION & SPILLING ===
Available slots: 4 registers (8 total - 4 reserved)
  [Reg] r1 (freq=25)
  [Reg] r3 (freq=18)
  [Reg] r6 (freq=15)
  [Reg] r8 (freq=12)
  [Mem@0x1000] r9 (freq=5)
  [Mem@0x1001] r10 (freq=3)
Summary: 4 in registers, 2 spilled

=== MEMORY MAP ===
  r9 -> 0x1000
  r10 -> 0x1001

=== Linearization ===
Generated 45 instructions

=== Compilation Complete ===
Output written to: output.risc
```

### Build the Compiler

```bash
# Build all modules
dune build

# Run compiler
dune exec MiniImpCompiler -- <args>

# Clean build artifacts
dune clean
```

---

## Design Philosophy Summary

Throughout this compiler implementation, we consistently chose:

1. **Correctness over Performance**
   - Simple, verifiable algorithms
   - Conservative assumptions (never merge I/O)
   - Explicit over implicit operations

2. **Pure Functional over Imperative**
   - No mutable state (`ref` cells)
   - Use `fold` instead of loops
   - Thread state through functions

3. **Early Optimization**
   - Simplify during translation (while structure visible)
   - Reduce work for later phases
   - Remove false dependencies early

4. **Explicit Intermediate Representations**
   - Visible CFG structure
   - Clear allocation maps
   - Detailed logging for debugging

5. **Separation of Concerns**
   - Each phase has one responsibility
   - Clear interfaces between modules
   - Independent, composable analyses

6. **Consistency**
   - Standardized logging (log_verbose)
   - Uniform error handling
   - Consistent coding style

These choices reflect the priorities of an **educational compiler project**: understanding and correctness first, performance second.

---

## Summary

This compiler demonstrates key concepts in compiler construction:
- **Frontend**: Lexing, parsing, AST construction
- **IR**: Control Flow Graphs
- **Analysis**: Dataflow analysis (forward MUST, backward MAY)
- **Optimization**: Algebraic simplification, coalescing, dead store elimination
- **Backend**: Register allocation, code generation

The implementation prioritizes **clarity and correctness**, making it suitable for learning compiler design principles.

**Key Takeaway**: A well-designed compiler is built from composable, verifiable phases. Each phase has a clear responsibility and clean interface, making the entire system easier to understand, debug, and extend.

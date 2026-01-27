# MiniImp Compiler - Register Allocation Implementation

## Overview

The MiniImp compiler now supports **register allocation** with configurable target architecture constraints. The compiler translates MiniImp programs to MiniRISC assembly code optimized for a specified number of physical registers.

## Features

### 1. **Register Allocation (Always Applied)**
   - **Always reduces** virtual registers to target number of physical registers
   - Frequency-based allocation prioritizes hot variables
   - Spills less-frequently-used variables to memory
   - Uses 2 reserved swap registers for load/store operations

### 2. **Liveness-Based Optimization (With `-O` flag)**
   - Uses liveness analysis to determine which variables are live at each program point
   - Implements **dead store elimination** (skips stores if value is not live)
   - More efficient code generation
   - Without `-O`: All stores are written (conservative approach)

### 3. **Configurable Target Architecture**
   - Supports any number of registers ≥ 4
   - Reserves 2 registers for internal operations (r_swap_1, r_swap_2)
   - Guarantees input/output registers remain in registers
   - Frequency-based allocation prioritizes hot variables

### 4. **Safety Checking**
   - Definite variables analysis (MUST/Forward analysis using greatest fixpoint)
   - Detects uninitialized register usage
   - Verifies all registers are defined before use
   - Optional flag to enable/disable

### 5. **Two Allocation Modes**
   - **Simple mode** (default): Frequency-based allocation, all stores written
   - **Optimized mode** (`-O`): Adds liveness analysis for dead store elimination

## Compiler Usage

```bash
MiniImpCompiler [OPTIONS] <num_registers> <input.minimp> <output.risc>
```

### Arguments

- `<num_registers>`: Number of target registers (must be ≥ 4)
- `<input.minimp>`: Input MiniImp program file
- `<output.risc>`: Output MiniRISC code file

### Options

- `-s, --safety`: Enable safety check for uninitialized variables
- `-O, --optimize`: Enable liveness-based optimization (dead store elimination)
- `-v, --verbose`: Verbose output (shows CFGs, analysis results)
- `-h, --help`: Display help

**Note**: Register allocation to the target number of registers **always happens**. The `-O` flag adds liveness analysis for better optimization (dead store elimination).

### Examples

```bash
# Basic compilation with 8 registers (simple allocation, no liveness optimization)
dune exec MiniImpCompiler -- 8 program.minimp output.risc

# With liveness-based optimization for dead store elimination
dune exec MiniImpCompiler -- -O 8 program.minimp output.risc

# With safety check and liveness optimization
dune exec MiniImpCompiler -- -s -O 6 program.minimp output.risc

# Verbose mode to see all intermediate steps
dune exec MiniImpCompiler -- -v -s -O 10 program.minimp output.risc

# Minimum registers (4) without optimization
dune exec MiniImpCompiler -- 4 program.minimp output.risc
```

## Architecture

### Compilation Pipeline

```
MiniImp Source
     ↓
Parse & Generate CFG
     ↓
Translate to MiniRISC CFG (unlimited virtual registers)
     ↓
[Optional] Safety Check (Definite Variables Analysis)
     ↓
Register Allocation (reduce to N physical registers)
     ├─ Without -O: Simple allocation (all stores written)
     └─ With -O: Liveness-based (dead store elimination)
     ↓
Linearize CFG
     ↓
Write MiniRISC Assembly
```

### Register Allocation Algorithm

1. **Frequency Analysis**: Count usage of each virtual register
2. **Allocation Decision**:
   - Reserve 2 registers for internal operations (r_swap_1, r_swap_2)
   - Guarantee r_in and r_out stay in registers
   - Allocate (N - 2) most frequently used registers to physical registers
   - Spill remaining registers to memory
3. **Instruction Rewriting**:
   - For each instruction, insert loads for spilled operands
   - Perform operation (possibly on temporaries)
   - Insert stores for spilled destinations (only if live)
4. **Dead Store Elimination**: Skip stores if destination is not live after instruction

### Data-Flow Analyses

#### 1. Definite Variables (Forward/MUST)
- **Direction**: Forward
- **Type**: MUST analysis (intersection)
- **Lattice**: Complete lattice of register sets, TOP = all registers
- **Purpose**: Detect uninitialized registers
- **Algorithm**: Greatest fixpoint iteration starting from TOP

#### 2. Live Variables (Backward/MAY)
- **Direction**: Backward
- **Type**: MAY analysis (union)
- **Lattice**: Complete lattice of register sets, BOTTOM = empty set
- **Purpose**: Register allocation, dead store elimination
- **Algorithm**: Least fixpoint iteration starting from BOTTOM

## Module Structure

### Core Modules

- **MiniImpSyntax**: MiniImp AST definitions
- **MiniImpParser/Lexer**: Parser and lexer for MiniImp
- **MiniImpCFG**: Control Flow Graph construction for MiniImp
- **MiniImpEval**: Interpreter for MiniImp

### MiniRISC Modules

- **MiniRISCSyntax**: MiniRISC instruction set and types
- **MiniRISCUtils**: Utility functions (register operations, string conversion)
- **MiniRISCCFG**: CFG representation for MiniRISC
- **MiniRISCLinearize**: Convert CFG to linear instruction sequence
- **MiniRISCOptimization**: Peephole optimizations

### Compiler Modules

- **MiniImpToRISC**: Translation from MiniImp CFG to MiniRISC CFG
- **DataflowAnalysis**: Data-flow analysis framework
  - `DefiniteVariables`: Safety checking
  - `LiveVariables`: Liveness analysis
  - `RegisterAllocation`: Register allocation and spilling

## Implementation Details

### Register Allocation Constraints

- **Minimum registers**: 4 (r_in, r_out, r_swap_1, r_swap_2)
- **Reserved registers**: 2 swap registers for load/store operations
- **Guaranteed registers**: Input and output must remain in registers

### Spilling Strategy

When a register is spilled to memory:
- **Load**: `LoadI addr, r_temp; Load r_temp, r_temp`
- **Store**: `LoadI addr, r_temp; Store r_value, r_temp`
- **Dead store elimination**: Skip store if value is not live

### Example

```ocaml
(* Original with unlimited registers *)
r3 := r1 + r2
r5 := r3 * r4

(* After allocation to 4 registers, r4 and r5 spilled *)
LoadI 0, r_swap1     (* load r4 from memory *)
Load r_swap1, r_swap1
r3 := r1 + r2
r_swap2 := r3 * r_swap1
LoadI 1, r_swap1     (* store r5 to memory *)
Store r_swap2, r_swap1
```

## Testing

Run the test script to verify all functionality:

```bash
./test_register_allocation.sh
```

Or test manually:

```bash
# Build the compiler
dune build

# Run with different configurations
dune exec MiniImpCompiler -- -v -s -O 6 examples/simple.minimp output.risc

# Check the output
cat output.risc
```

## Future Enhancements

- **Graph coloring**: Use interference graph for better allocation
- **Linear scan allocation**: Faster allocation for large programs
- **Register coalescing**: Reduce unnecessary copies
- **Spill cost analysis**: Choose better spill candidates
- **Live range splitting**: Split live ranges to reduce register pressure

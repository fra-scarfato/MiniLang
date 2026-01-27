# MiniRISC Compiler

A complete compiler from MiniImp (imperative mini-language) to MiniRISC (RISC-like assembly).

## Architecture

### Module Organization

#### Core Language Modules
- **MiniRISCSyntax**: AST definitions for MiniRISC instructions
- **MiniRISCUtils**: Shared utilities (register operations, string conversions)
- **MiniRISCCFG**: Control Flow Graph representation
- **MiniRISCLinearize**: Convert CFG to sequential program

#### Analysis Modules
- **DataflowAnalysis**: Data-flow analysis framework
  - `DefiniteVariables`: Must analysis for initialized variables (maximal fixpoint)
  - `LiveVariables`: May analysis for register liveness (minimal fixpoint)

#### Compilation Modules
- **MiniImpToRISC**: MiniImp → MiniRISC translation
- **MiniRISCOptimization**: Peephole optimizations
- **MiniRISCCompiler**: Main compilation orchestration

### Compiler Features

1. **Safety Checking** (`-s, --safety`)
   - Performs definite variables analysis (Must/Forward)
   - Detects uninitialized register usage
   - Fails compilation if unsafe code detected

2. **Optimization** (`-O, --optimize`)
   - Peephole optimizations:
     - Remove redundant copies (`copy r1 r1` → removed)
     - Fold consecutive copies (`copy r1 r2; copy r2 r3` → `copy r1 r3`)
     - Remove nops
     - Combine load-immediate with copy

3. **Register Management** (`-r, --registers N`)
   - Specify maximum number of available registers
   - Currently for documentation (allocation not yet implemented)

## Usage

```bash
# Build the compiler
dune build

# Basic compilation
MiniImpCompiler input.minimp output.risc

# With safety checking
MiniImpCompiler -s input.minimp output.risc

# With optimizations
MiniImpCompiler -O input.minimp output.risc

# Verbose output (shows CFG and statistics)
MiniImpCompiler -v -s -O input.minimp output.risc

# With all options
MiniImpCompiler -r 16 -s -O -v input.minimp output.risc
```

## Options

- `-r, --registers N` - Maximum number of registers (default: unlimited)
- `-s, --safety` - Enable safety check for uninitialized variables
- `-O, --optimize` - Enable peephole optimizations  
- `-v, --verbose` - Verbose output (print CFG and statistics)
- `-h, --help` - Display help message

## Example

Given `test.minimp`:
```
program factorial(n; result)
  var x;
  begin
    x := n;
    result := 1;
    while x > 0 do
      result := result * x;
      x := x - 1
    done
  end
```

Compile with:
```bash
MiniImpCompiler -s -O -v test.minimp factorial.risc
```

Output includes:
- Safety check result
- Number of blocks and instructions
- Control flow graph (if verbose)
- Generated RISC code in `factorial.risc`

## Data-Flow Analyses

### Definite Variables (Must Analysis)
- **Direction**: Forward
- **Lattice**: Subsets of registers
- **Join**: Intersection (∩)
- **Initialization**: Optimistic (all registers defined everywhere except entry)
- **Purpose**: Ensure all registers initialized before use

### Live Variables (May Analysis)
- **Direction**: Backward
- **Lattice**: Subsets of registers
- **Join**: Union (∪)
- **Initialization**: Pessimistic (empty set)
- **Purpose**: Register allocation, dead code elimination

## File Organization

```
lib/miniRISC/
├── MiniRISCSyntax.ml       # AST definitions
├── MiniRISCUtils.ml        # Shared utilities
├── MiniRISCCFG.ml          # Control flow graph
├── DataflowAnalysis.ml     # Data-flow analyses
├── MiniRISCOptimization.ml # Optimizations
├── MiniImpToRISC.ml        # Translation
├── MiniRISCLinearize.ml    # CFG → sequential
├── MiniRISCCompiler.mli    # Compiler interface
└── MiniRISCCompiler.ml     # Compiler implementation

bin/
├── MiniImpCompiler.ml      # CLI executable
└── MiniImpInterpreter.ml   # Original interpreter
```

## Implementation Notes

- **Register conventions**: 
  - `r_in` - Input parameter (always initialized)
  - `r_out` - Output result (always used)
  - `rN` - Temporary registers (r0, r1, r2, ...)

- **Optimizations are local**: Peephole optimizations operate on instruction sequences within blocks

- **Safety is conservative**: Must analysis ensures no false negatives (will reject some safe programs)

## Usage Examples

```bash
# Basic compilation
MiniImpCompiler input.minimp output.risc

# With safety + optimization + verbose
MiniImpCompiler -s -O -v input.minimp output.risc

# Specify max registers
MiniImpCompiler -r 16 -s -O input.minimp output.risc
```

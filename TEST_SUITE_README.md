# MiniImp Compiler Test Suite

This directory contains comprehensive test cases for all components of the MiniImp compiler.

## Test Categories

### 1. Parser Error Tests (`test_parser_error_*.minimp`)
Tests that verify the parser correctly rejects invalid syntax.

- **test_parser_error_1.minimp**: Missing closing parenthesis
- **test_parser_error_2.minimp**: Invalid token (@)
- **test_parser_error_3.minimp**: Missing semicolon between statements
- **test_parser_error_4.minimp**: Missing 'do' keyword in while loop
- **test_parser_error_5.minimp**: Missing 'output' keyword in function definition

**Expected Output**: Parse error messages from lexer/parser

**How to Test**:
```bash
dune exec MiniImpCompiler -- 8 test_ex/test_parser_error_1.minimp output.risc
# Should fail with parse error
```

### 2. Safety Analysis Tests (`test_safety_*.minimp`)
Tests for the definite variables analysis (MUST/Forward analysis) that detects uninitialized variable usage.

- **test_safety_error_1.minimp**: Direct use of uninitialized variable
- **test_safety_error_2.minimp**: Variable initialized only in one branch
- **test_safety_error_3.minimp**: Variable used in loop before initialization
- **test_safety_ok_1.minimp**: All variables properly initialized (should pass)

**Expected Output**: 
- Error cases: Safety check failure message
- OK case: Compilation success

**How to Test**:
```bash
dune exec MiniImpCompiler -- -s 8 test_ex/test_safety_error_1.minimp output.risc
# Should fail with "Safety check failed: uninitialized variable" message

dune exec MiniImpCompiler -- -s 8 test_ex/test_safety_ok_1.minimp output.risc
# Should succeed with "Safety check passed" message
```

### 3. Register Allocation Tests (`test_register_pressure_*.minimp`)
Tests that exercise the register allocation algorithm with varying pressure.

- **test_register_pressure_1.minimp**: High pressure - 8 variables all live simultaneously
  - With 4 registers: Should trigger heavy spilling
  - With 8 registers: Should work better with some spilling
  - With 12 registers: Should work well with minimal/no spilling

- **test_register_pressure_2.minimp**: Low pressure - sequential variable usage
  - Should demonstrate register coalescing/merging
  - Non-overlapping lifetimes allow efficient reuse

**Expected Output**: With `-v` flag, shows:
- Number of virtual registers before allocation
- Number of registers after coalescing/merging
- Which registers were spilled to memory
- Memory addresses assigned to spilled variables

**How to Test**:
```bash
# High pressure with different register counts
dune exec MiniImpCompiler -- -v 4 test_ex/test_register_pressure_1.minimp output.risc
# Should show: "Spilling required", memory operations added

dune exec MiniImpCompiler -- -v 12 test_ex/test_register_pressure_1.minimp output.risc
# Should show: Less or no spilling

# Sequential usage - efficient merging
dune exec MiniImpCompiler -- -v 4 test_ex/test_register_pressure_2.minimp output.risc
# Should show: Registers merged/coalesced efficiently
```

### 4. Optimization Tests (`test_dead_code_*.minimp`, `test_optimization_*.minimp`)
Tests for liveness analysis and dead code elimination.

- **test_dead_code_1.minimp**: Variable assigned but never read
- **test_dead_code_2.minimp**: Dead code in conditional branches
- **test_optimization_1.minimp**: Copy propagation opportunities (a=x; b=a; c=b)

**Expected Output**: With `-O` flag:
- Dead stores eliminated (not written to memory)
- Fewer instructions in final code
- Register coalescing on copy chains

**How to Test**:
```bash
# Without optimization
dune exec MiniImpCompiler -- -v 8 test_ex/test_dead_code_1.minimp output1.risc
# All stores written

# With optimization
dune exec MiniImpCompiler -- -O -v 8 test_ex/test_dead_code_1.minimp output2.risc
# Dead stores eliminated, compare instruction counts

# Compare outputs
diff output1.risc output2.risc
```

### 5. Complex Program Tests (`test_complex_*.minimp`)
Real-world programs testing multiple features together.

- **test_complex_1.minimp**: Factorial computation
  - Tests: loops, conditionals, multiple variables, safety
- **test_complex_2.minimp**: Fibonacci-like computation
  - Tests: variable dependencies, loops, temporary values
- **test_complex_3.minimp**: Nested conditionals and loops
  - Tests: complex control flow, multiple paths

**Expected Output**: Should compile successfully with all optimizations

**How to Test**:
```bash
# Factorial with all features
dune exec MiniImpCompiler -- -s -O -v 8 test_ex/test_complex_1.minimp output.risc
# Should show: Safety passed, optimization stats, compilation success

# With minimal registers
dune exec MiniImpCompiler -- -s -O -v 4 test_ex/test_complex_1.minimp output.risc
# Should show: More spilling but still correct
```

### 6. Arithmetic and Boolean Expression Tests
Tests for correct expression evaluation.

- **test_arithmetic_1.minimp**: Operator precedence (* before +, -)
- **test_arithmetic_2.minimp**: Nested parentheses
- **test_boolean_1.minimp**: Boolean AND operator
- **test_boolean_2.minimp**: NOT precedence over AND

**Expected Output**: Correct evaluation order

**How to Test**:
```bash
dune exec MiniImpCompiler -- 8 test_ex/test_arithmetic_1.minimp output.risc
# Should compile correctly
```

### 7. Edge Case Tests (`test_edge_case_*.minimp`)
Boundary conditions and special cases.

- **test_edge_case_1.minimp**: Empty loop body (skip statement)
- **test_edge_case_2.minimp**: Negative number literals
- **test_edge_case_3.minimp**: Direct input-to-output (y = x)
  - Should coalesce input and output registers
- **test_edge_case_4.minimp**: Multiple assignments to same variable

**Expected Output**: Should handle all cases correctly

**How to Test**:
```bash
dune exec MiniImpCompiler -- -v 4 test_ex/test_edge_case_3.minimp output.risc
# Should show efficient register usage, input/output coalesced if possible
```

## Running All Tests

Use the provided test runner script:

```bash
chmod +x run_all_tests.sh
./run_all_tests.sh
```

This will:
1. Build the compiler
2. Run all test categories
3. Show results with color coding (green=pass, red=fail)
4. Save all outputs to `test_output/` directory
5. Provide a summary of passed/failed tests

## Understanding Compiler Output

### Safety Check Output
```
Safety check passed
- All variables initialized before use
```

or

```
Safety check failed: Variable 'x' may be uninitialized at line 5
```

### Register Allocation Output (with `-v` flag)

```
Virtual registers before allocation: 10
Registers after coalescing: 6
Target registers: 4
Spilling required: yes

Register allocation:
  r_in -> r_in (input, never spilled)
  r_out -> r_out (output, never spilled)
  r0 -> r0 (most frequent)
  r1 -> r1
  r2 -> r2
  r3 -> r3
  r4 -> MEMORY[0x1000] (spilled)
  r5 -> MEMORY[0x1004] (spilled)
```

### Optimization Output (with `-O -v` flags)

```
Liveness analysis complete
Dead stores eliminated: 3
Instructions before optimization: 45
Instructions after optimization: 42
```

### Statistics

```
CFG Statistics:
  Blocks: 8
  Instructions: 42
  Max live variables: 5
```

## Test Matrix

| Test Category | Without flags | -s | -O | -v | -s -O -v | Registers |
|---------------|---------------|----|----|-------|----------|-----------|
| Parser Errors | ✓ | | | | | any |
| Safety Errors | | ✓ | | | | any |
| Safety OK | | ✓ | | | | any |
| Register Pressure | ✓ | | | ✓ | | 4, 8, 12 |
| Dead Code | ✓ | | ✓ | ✓ | | 8 |
| Optimization | ✓ | | ✓ | ✓ | | 8 |
| Complex Programs | ✓ | ✓ | ✓ | ✓ | ✓ | 4, 8, 10 |
| Expressions | ✓ | | | | | 8 |
| Edge Cases | ✓ | | | ✓ | | 4, 8 |

## What Each Flag Does

- **No flags**: Basic compilation, allocate to N registers
- **`-s`**: Enable safety checking (definite variables analysis)
- **`-O`**: Enable liveness-based optimization (dead store elimination)
- **`-v`**: Verbose output (shows CFG, analysis results, statistics)
- **`-s -O -v`**: All features enabled (most comprehensive testing)

## Expected Behavior Summary

### Parser should:
- ✓ Reject missing parentheses, keywords, semicolons
- ✓ Reject invalid tokens
- ✓ Accept valid syntax according to grammar

### Safety Analysis should:
- ✓ Detect uninitialized variables
- ✓ Handle conditional initialization correctly
- ✓ Pass when all variables are initialized

### Register Allocation should:
- ✓ Work with any N ≥ 4 registers
- ✓ Coalesce/merge registers when possible
- ✓ Spill to memory when necessary
- ✓ Never spill input/output registers
- ✓ Use r_a, r_b for memory operations

### Optimization should:
- ✓ Eliminate dead stores with `-O` flag
- ✓ Keep all stores without `-O` flag
- ✓ Coalesce copy chains
- ✓ Reduce instruction count

### Complex Programs should:
- ✓ Compile correctly with all combinations of flags
- ✓ Handle loops, conditionals, multiple variables
- ✓ Work with minimal registers (4) and abundant registers (12+)

## Debugging Failed Tests

If a test fails, check:
1. The log file in `test_output/<test_name>.log`
2. The generated RISC code in `test_output/<test_name>.risc`
3. Run the compiler manually with `-v` for detailed output
4. Compare with expected behavior described in test comments

## Adding New Tests

To add a new test:
1. Create `test_ex/test_<category>_<number>.minimp`
2. Add comment at top describing expected behavior
3. Add test case to `run_all_tests.sh` in appropriate section
4. Document in this README

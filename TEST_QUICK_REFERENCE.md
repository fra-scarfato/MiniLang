# MiniImp Compiler Test Suite - Quick Reference

## Quick Start

```bash
# Run all tests
./run_all_tests.sh

# Run individual test
dune exec MiniImpCompiler -- [FLAGS] <num_registers> <input.minimp> <output.risc>
```

## Test Categories & Expected Outputs

### 1. 🔴 PARSER ERRORS (Should FAIL to parse)
```bash
# Missing parenthesis
dune exec MiniImpCompiler -- 8 test_ex/test_parser_error_1.minimp output.risc
# Expected: Parse error

# Invalid token
dune exec MiniImpCompiler -- 8 test_ex/test_parser_error_2.minimp output.risc
# Expected: Lexer/Parser error
```

**What to look for**: Error messages from lexer or parser indicating syntax problems.

---

### 2. 🔴 SAFETY ERRORS (Should FAIL safety check)
```bash
# Uninitialized variable
dune exec MiniImpCompiler -- -s 8 test_ex/test_safety_error_1.minimp output.risc
# Expected: "Safety check failed: uninitialized variable 'z'"

# Conditional initialization
dune exec MiniImpCompiler -- -s 8 test_ex/test_safety_error_2.minimp output.risc
# Expected: "Safety check failed" - variable not initialized on all paths
```

**What to look for**: 
- Error message: "Safety check failed"
- Variable name that's uninitialized
- Line/location information

---

### 3. 🟢 SAFETY OK (Should PASS safety check)
```bash
dune exec MiniImpCompiler -- -s -v 8 test_ex/test_safety_ok_1.minimp output.risc
# Expected: "Safety check passed"
```

**What to look for**:
- "Safety check passed" message
- Successful compilation
- Generated .risc file

---

### 4. 📊 REGISTER ALLOCATION (Various behaviors)

#### High Register Pressure (8 live variables)
```bash
# With 4 registers - HEAVY SPILLING
dune exec MiniImpCompiler -- -v 4 test_ex/test_register_pressure_1.minimp output.risc
```
**Expected Output**:
```
Virtual registers before allocation: 10
Registers after coalescing: 9
Target registers: 4
Spilling required: YES

Spilled registers:
  r4 -> MEMORY[0x1000]
  r5 -> MEMORY[0x1004]
  r6 -> MEMORY[0x1008]
  r7 -> MEMORY[0x100c]
  r8 -> MEMORY[0x1010]
```

```bash
# With 12 registers - MINIMAL/NO SPILLING
dune exec MiniImpCompiler -- -v 12 test_ex/test_register_pressure_1.minimp output.risc
```
**Expected Output**:
```
Virtual registers before allocation: 10
Target registers: 12
Spilling required: NO (or minimal)
```

#### Low Register Pressure (Sequential usage)
```bash
dune exec MiniImpCompiler -- -v 4 test_ex/test_register_pressure_2.minimp output.risc
```
**Expected Output**:
```
Virtual registers before allocation: 8
Registers after coalescing: 2-3 (merged efficiently!)
Target registers: 4
Spilling required: NO

Merged registers:
  r1, r2, r3 -> r0 (non-overlapping lifetimes)
```

**What to look for**:
- "Registers after coalescing" < "Virtual registers before" = GOOD (merging worked)
- With low target count: "Spilling required: YES", see MEMORY[] addresses
- With high target count: "Spilling required: NO"
- Load/store instructions in .risc file for spilled variables

---

### 5. ⚡ OPTIMIZATION (Dead Code Elimination)

#### WITHOUT -O flag
```bash
dune exec MiniImpCompiler -- -v 8 test_ex/test_dead_code_1.minimp output1.risc
```
**Expected**: All stores written, even for unused variables

#### WITH -O flag
```bash
dune exec MiniImpCompiler -- -O -v 8 test_ex/test_dead_code_1.minimp output2.risc
```
**Expected Output**:
```
Liveness analysis: ON
Dead stores eliminated: 1-2
Instructions optimized

# Compare files:
Instructions in output1.risc: ~15
Instructions in output2.risc: ~12 (fewer!)
```

**What to look for**:
- "Dead stores eliminated: N" message
- Fewer instructions with -O flag
- Unused variable stores removed from .risc file

---

### 6. 🎯 COMPLEX PROGRAMS (Real-world tests)

#### Factorial
```bash
# All features enabled
dune exec MiniImpCompiler -- -s -O -v 8 test_ex/test_complex_1.minimp output.risc
```
**Expected Output**:
```
Safety check: PASSED
Optimization: ON
Liveness analysis: Complete
Dead stores eliminated: 0-1

CFG Statistics:
  Blocks: 5-7
  Instructions: 20-30
  
Compilation successful!
```

#### With Minimal Registers
```bash
dune exec MiniImpCompiler -- -s -O -v 4 test_ex/test_complex_1.minimp output.risc
```
**Expected**: More spilling but still compiles correctly

**What to look for**:
- All checks pass
- Reasonable instruction count
- Memory operations if registers are limited

---

### 7. 🧮 EXPRESSIONS (Should compile correctly)
```bash
# Arithmetic precedence
dune exec MiniImpCompiler -- 8 test_ex/test_arithmetic_1.minimp output.risc
# Expected: Compiles, respects * before +

# Boolean expressions
dune exec MiniImpCompiler -- 8 test_ex/test_boolean_2.minimp output.risc
# Expected: Compiles, respects NOT before AND
```

---

### 8. 🔧 EDGE CASES

#### Direct Input-to-Output
```bash
dune exec MiniImpCompiler -- -v 4 test_ex/test_edge_case_3.minimp output.risc
```
**Expected Output**:
```
Minimal register usage
Possibly: r_in coalesced with r_out (if allowed)
Very few instructions (~1-2)
```

## Comparison Examples

### Example 1: Effect of Register Count

```bash
# Same program, different register counts
dune exec MiniImpCompiler -- -v 4 test_ex/test_register_pressure_1.minimp out_4.risc
dune exec MiniImpCompiler -- -v 8 test_ex/test_register_pressure_1.minimp out_8.risc
dune exec MiniImpCompiler -- -v 12 test_ex/test_register_pressure_1.minimp out_12.risc

# Compare file sizes and instruction counts
wc -l out_*.risc
# Expect: out_4.risc largest (many load/store), out_12.risc smallest
```

### Example 2: Effect of -O Flag

```bash
# Without optimization
dune exec MiniImpCompiler -- -v 8 test_ex/test_dead_code_1.minimp no_opt.risc
# With optimization
dune exec MiniImpCompiler -- -O -v 8 test_ex/test_dead_code_1.minimp with_opt.risc

# Compare
diff no_opt.risc with_opt.risc
# Expect: with_opt.risc has fewer store instructions
```

### Example 3: Full Feature Comparison

```bash
# Basic
dune exec MiniImpCompiler -- 8 test_ex/test_complex_1.minimp basic.risc

# With safety
dune exec MiniImpCompiler -- -s 8 test_ex/test_complex_1.minimp safety.risc

# With optimization
dune exec MiniImpCompiler -- -O 8 test_ex/test_complex_1.minimp opt.risc

# Everything
dune exec MiniImpCompiler -- -s -O -v 8 test_ex/test_complex_1.minimp full.risc
```

## Interpreting Verbose Output

### Register Coalescing Section
```
=== Register Coalescing ===
Before: 10 virtual registers
Interference analysis...
Merging: r3 <- r5 (non-interfering)
Merging: r2 <- r7 (non-interfering)
After: 6 virtual registers
```
**Good**: Many merges = efficient! Fewer registers to allocate.

### Allocation Section
```
=== Register Allocation ===
Target: 4 physical registers
Available for variables: 0 (4 - 4 reserved)
Frequency-based allocation:
  r0 (freq: 15) -> r0
  r1 (freq: 12) -> r1
  r2 (freq: 8) -> r2
  r3 (freq: 6) -> r3
  r4 (freq: 3) -> MEMORY[0x1000]
```
**Interpretation**: Higher frequency variables get physical registers, rest spilled.

### Liveness Section (with -O)
```
=== Liveness Analysis ===
Block 1: Live-out = {r0, r1}
Block 2: Live-out = {r1, r2}
Dead store detected at instruction 15
Dead store detected at instruction 23
```
**Interpretation**: Optimization identifies stores that can be eliminated.

## Common Patterns to Verify

### ✓ Parser Accepts Valid Syntax
- Arithmetic: `2 + 3 * 4`
- Nested: `((a + b) * c)`
- Loops: `while x < 10 do ...`
- Conditionals: `if ... then ... else ...`

### ✓ Parser Rejects Invalid Syntax
- Missing parens, keywords, semicolons
- Invalid tokens
- Malformed structures

### ✓ Safety Analysis Works
- Detects uninitialized reads
- Handles control flow (branches, loops)
- Passes when code is safe

### ✓ Register Allocation Adapts
- Low registers → more spilling
- High registers → less spilling
- Sequential code → good coalescing

### ✓ Optimization Reduces Code
- Dead stores removed with -O
- All stores kept without -O
- Copy chains optimized

## Troubleshooting

### Test fails to compile (unexpectedly)
1. Check log: `test_output/<test_name>.log`
2. Run manually with -v flag
3. Verify syntax is correct
4. Check if error is expected (parser/safety tests)

### No spilling when expected
- Target register count might be too high
- Code might use fewer variables than expected
- Coalescing might be very effective

### No optimization observed
- Make sure -O flag is used
- Check if code actually has dead stores
- With -v, look for "Dead stores eliminated: N"

### Safety check false positive/negative
- Review definite variables algorithm (MUST analysis)
- Check control flow paths
- Conditional initialization is conservative (fails if ANY path misses initialization)

## Success Criteria

A comprehensive test run should show:
- ✓ All parser error tests fail (as expected)
- ✓ All safety error tests fail with -s (as expected)  
- ✓ All safety OK tests pass with -s
- ✓ Register allocation works with 4, 8, 12 registers
- ✓ Spilling increases with lower register counts
- ✓ Optimization (-O) reduces instruction count
- ✓ Complex programs compile with all flag combinations
- ✓ All expression and edge case tests compile successfully

#!/bin/bash
# Comprehensive Test Suite for MiniImp Compiler
# This script tests all aspects of the compiler including:
# - Parser errors
# - Safety analysis
# - Register allocation
# - Optimization (dead code elimination)
# - Complex programs
# - Edge cases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build the compiler first
echo -e "${BLUE}Building compiler...${NC}"
dune build
echo ""

COMPILER="dune exec MiniImpCompiler --"
TEST_DIR="test_ex"
OUTPUT_DIR="test_output"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Test counters
TOTAL=0
PASSED=0
FAILED=0

# Function to run a test
run_test() {
    local test_file=$1
    local test_name=$(basename "$test_file" .minimp)
    local flags=$2
    local num_regs=$3
    local expected=$4
    
    TOTAL=$((TOTAL + 1))
    
    echo -e "${YELLOW}Test #${TOTAL}: ${test_name}${NC}"
    echo "  File: $test_file"
    echo "  Flags: $flags"
    echo "  Registers: $num_regs"
    echo "  Expected: $expected"
    
    local output_file="$OUTPUT_DIR/${test_name}.risc"
    local log_file="$OUTPUT_DIR/${test_name}.log"
    
    # Run compiler and capture output
    if $COMPILER $flags $num_regs "$test_file" "$output_file" > "$log_file" 2>&1; then
        if [[ $expected == *"SUCCESS"* ]] || [[ $expected == *"compile correctly"* ]]; then
            echo -e "  ${GREEN}✓ PASSED${NC} - Compiled successfully"
            PASSED=$((PASSED + 1))
            # Show interesting parts of output
            if [[ $flags == *"-v"* ]]; then
                echo "  Output highlights:"
                grep -E "(Register allocation|Merging|Spilling|Safety|blocks|instructions)" "$log_file" | head -10 | sed 's/^/    /'
            fi
        else
            echo -e "  ${RED}✗ FAILED${NC} - Expected to fail but succeeded"
            FAILED=$((FAILED + 1))
        fi
    else
        if [[ $expected == *"Parse error"* ]] || [[ $expected == *"Safety"* ]] || [[ $expected == *"ERROR"* ]]; then
            echo -e "  ${GREEN}✓ PASSED${NC} - Failed as expected"
            PASSED=$((PASSED + 1))
            # Show error message
            echo "  Error message:"
            tail -5 "$log_file" | sed 's/^/    /'
        else
            echo -e "  ${RED}✗ FAILED${NC} - Expected to succeed but failed"
            FAILED=$((FAILED + 1))
            echo "  Error log:"
            cat "$log_file" | sed 's/^/    /'
        fi
    fi
    echo ""
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  MINIMP COMPILER TEST SUITE${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ============================================================
# SECTION 1: PARSER ERROR TESTS
# ============================================================
echo -e "${BLUE}=== SECTION 1: PARSER ERROR TESTS ===${NC}"
echo "Testing that parser correctly rejects invalid syntax"
echo ""

run_test "$TEST_DIR/test_parser_error_1.minimp" "" "8" "Parse error - missing closing parenthesis"
run_test "$TEST_DIR/test_parser_error_2.minimp" "" "8" "Parse error - invalid token"
run_test "$TEST_DIR/test_parser_error_3.minimp" "" "8" "Parse error - missing semicolon"
run_test "$TEST_DIR/test_parser_error_4.minimp" "" "8" "Parse error - missing 'do'"
run_test "$TEST_DIR/test_parser_error_5.minimp" "" "8" "Parse error - missing 'output'"

# ============================================================
# SECTION 2: SAFETY ANALYSIS TESTS
# ============================================================
echo -e "${BLUE}=== SECTION 2: SAFETY ANALYSIS TESTS ===${NC}"
echo "Testing definite variables analysis (uninitialized variable detection)"
echo ""

run_test "$TEST_DIR/test_safety_error_1.minimp" "-s" "8" "Safety check failed - uninitialized variable"
run_test "$TEST_DIR/test_safety_error_2.minimp" "-s" "8" "Safety check failed - conditional initialization"
run_test "$TEST_DIR/test_safety_error_3.minimp" "-s" "8" "Safety check failed - loop without initialization"
run_test "$TEST_DIR/test_safety_ok_1.minimp" "-s" "8" "SUCCESS - All variables initialized"

# ============================================================
# SECTION 3: REGISTER ALLOCATION TESTS
# ============================================================
echo -e "${BLUE}=== SECTION 3: REGISTER ALLOCATION TESTS ===${NC}"
echo "Testing register allocation with different register counts"
echo ""

echo -e "${YELLOW}3.1: High Register Pressure${NC}"
run_test "$TEST_DIR/test_register_pressure_1.minimp" "-v" "4" "SUCCESS - Should trigger spilling with 4 registers"
run_test "$TEST_DIR/test_register_pressure_1.minimp" "-v" "8" "SUCCESS - Should work better with 8 registers"
run_test "$TEST_DIR/test_register_pressure_1.minimp" "-v" "12" "SUCCESS - Should work well with 12 registers"

echo -e "${YELLOW}3.2: Low Register Pressure (Sequential)${NC}"
run_test "$TEST_DIR/test_register_pressure_2.minimp" "-v" "4" "SUCCESS - Should merge registers efficiently"
run_test "$TEST_DIR/test_register_pressure_2.minimp" "-v" "6" "SUCCESS - Should merge registers"

# ============================================================
# SECTION 4: OPTIMIZATION TESTS
# ============================================================
echo -e "${BLUE}=== SECTION 4: OPTIMIZATION TESTS ===${NC}"
echo "Testing liveness analysis and dead code elimination"
echo ""

echo -e "${YELLOW}4.1: Without Optimization${NC}"
run_test "$TEST_DIR/test_dead_code_1.minimp" "-v" "8" "SUCCESS - No optimization, keeps all stores"

echo -e "${YELLOW}4.2: With Optimization (-O flag)${NC}"
run_test "$TEST_DIR/test_dead_code_1.minimp" "-O -v" "8" "SUCCESS - Dead store elimination"
run_test "$TEST_DIR/test_dead_code_2.minimp" "-O -v" "8" "SUCCESS - Dead code in branches"

echo -e "${YELLOW}4.3: Register Coalescing${NC}"
run_test "$TEST_DIR/test_optimization_1.minimp" "-v" "8" "SUCCESS - Should coalesce copy chains"

# ============================================================
# SECTION 5: COMPLEX PROGRAM TESTS
# ============================================================
echo -e "${BLUE}=== SECTION 5: COMPLEX PROGRAM TESTS ===${NC}"
echo "Testing complete programs with multiple features"
echo ""

run_test "$TEST_DIR/test_complex_1.minimp" "-s -O -v" "8" "SUCCESS - Factorial with all optimizations"
run_test "$TEST_DIR/test_complex_1.minimp" "-s -v" "4" "SUCCESS - Factorial with low registers"
run_test "$TEST_DIR/test_complex_2.minimp" "-s -O -v" "8" "SUCCESS - Fibonacci-like computation"
run_test "$TEST_DIR/test_complex_3.minimp" "-s -O -v" "10" "SUCCESS - Nested conditionals and loops"

# ============================================================
# SECTION 6: ARITHMETIC AND BOOLEAN EXPRESSION TESTS
# ============================================================
echo -e "${BLUE}=== SECTION 6: EXPRESSION TESTS ===${NC}"
echo "Testing arithmetic and boolean expression evaluation"
echo ""

run_test "$TEST_DIR/test_arithmetic_1.minimp" "" "8" "SUCCESS - Operator precedence"
run_test "$TEST_DIR/test_arithmetic_2.minimp" "" "8" "SUCCESS - Nested parentheses"
run_test "$TEST_DIR/test_boolean_1.minimp" "" "8" "SUCCESS - Boolean AND"
run_test "$TEST_DIR/test_boolean_2.minimp" "" "8" "SUCCESS - Boolean NOT precedence"

# ============================================================
# SECTION 7: EDGE CASE TESTS
# ============================================================
echo -e "${BLUE}=== SECTION 7: EDGE CASE TESTS ===${NC}"
echo "Testing boundary conditions and special cases"
echo ""

run_test "$TEST_DIR/test_edge_case_1.minimp" "" "8" "SUCCESS - Empty loop (skip)"
run_test "$TEST_DIR/test_edge_case_2.minimp" "" "8" "SUCCESS - Negative numbers"
run_test "$TEST_DIR/test_edge_case_3.minimp" "-v" "4" "SUCCESS - Direct input to output (minimal registers)"
run_test "$TEST_DIR/test_edge_case_4.minimp" "" "8" "SUCCESS - Multiple assignments to same variable"

# ============================================================
# SECTION 8: STRESS TESTS
# ============================================================
echo -e "${BLUE}=== SECTION 8: STRESS TESTS ===${NC}"
echo "Testing extreme conditions"
echo ""

echo -e "${YELLOW}8.1: Minimum Registers (4)${NC}"
run_test "$TEST_DIR/test_complex_1.minimp" "-s -O -v" "4" "SUCCESS - Complex program with minimum registers"

echo -e "${YELLOW}8.2: Safety + Optimization Combined${NC}"
run_test "$TEST_DIR/test_complex_2.minimp" "-s -O -v" "6" "SUCCESS - All features together"

# ============================================================
# FINAL SUMMARY
# ============================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  TEST SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total tests: ${TOTAL}"
echo -e "${GREEN}Passed: ${PASSED}${NC}"
echo -e "${RED}Failed: ${FAILED}${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! 🎉${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Check logs in $OUTPUT_DIR/${NC}"
    exit 1
fi

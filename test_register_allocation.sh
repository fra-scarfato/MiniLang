#!/bin/bash

# Test script for MiniImp compiler with register allocation

echo "========================================="
echo "Testing MiniImpCompiler with Register Allocation"
echo "========================================="

# Test file
TEST_FILE="examples/simple.minimp"
OUTPUT_FILE="output_test.risc"

echo ""
echo "Test 1: Compile with 4 registers (minimum)"
echo "-----------------------------------------"
dune exec MiniImpCompiler -- 4 "$TEST_FILE" "$OUTPUT_FILE"

echo ""
echo "Test 2: Compile with 8 registers and verbose output"
echo "----------------------------------------------------"
dune exec MiniImpCompiler -- -v 8 "$TEST_FILE" "$OUTPUT_FILE"

echo ""
echo "Test 3: Compile with 6 registers, safety check, and optimization"
echo "----------------------------------------------------------------"
dune exec MiniImpCompiler -- -s -O -v 6 "$TEST_FILE" "$OUTPUT_FILE"

echo ""
echo "Test 4: Show generated code"
echo "----------------------------"
if [ -f "$OUTPUT_FILE" ]; then
    echo "Content of $OUTPUT_FILE:"
    cat "$OUTPUT_FILE"
else
    echo "Output file not found!"
fi

echo ""
echo "Test 5: Try with invalid number of registers (should fail)"
echo "-----------------------------------------------------------"
dune exec MiniImpCompiler -- 3 "$TEST_FILE" "$OUTPUT_FILE" 2>&1 || echo "Failed as expected"

echo ""
echo "========================================="
echo "All tests completed!"
echo "========================================="

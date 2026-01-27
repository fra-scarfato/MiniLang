#!/bin/bash
# Test script for MiniRISC Compiler

echo "=== MiniRISC Compiler Test Suite ==="
echo ""

# Build the compiler
echo "Building compiler..."
dune build || exit 1
echo "✓ Build successful"
echo ""

# Test directory
TEST_DIR="test_ex"
OUTPUT_DIR="test_output"
mkdir -p "$OUTPUT_DIR"

# Function to run a test
run_test() {
    local input_file=$1
    local test_name=$(basename "$input_file" .minimp)
    local output_file="$OUTPUT_DIR/${test_name}.risc"
    
    echo "Testing: $test_name"
    
    # Test 1: Basic compilation
    if ./_build/default/bin/MiniImpCompiler.exe "$input_file" "$output_file" 2>&1 | grep -q "successful"; then
        echo "  ✓ Basic compilation"
    else
        echo "  ✗ Basic compilation failed"
        return 1
    fi
    
    # Test 2: With safety check
    if ./_build/default/bin/MiniImpCompiler.exe -s "$input_file" "$output_file.safe" 2>&1; then
        echo "  ✓ Safety check passed"
    else
        echo "  ✗ Safety check failed"
    fi
    
    # Test 3: With optimization
    if ./_build/default/bin/MiniImpCompiler.exe -O "$input_file" "$output_file.opt" 2>&1 | grep -q "successful"; then
        echo "  ✓ Optimization"
    else
        echo "  ✗ Optimization failed"
    fi
    
    # Test 4: Full compilation
    if ./_build/default/bin/MiniImpCompiler.exe -s -O -v "$input_file" "$output_file.full" 2>&1 | grep -q "successful"; then
        echo "  ✓ Full compilation (safe + optimized)"
    else
        echo "  ✗ Full compilation failed"
    fi
    
    echo ""
}

# Run tests on all test files
if [ -d "$TEST_DIR" ]; then
    for file in "$TEST_DIR"/*.minimp; do
        if [ -f "$file" ]; then
            run_test "$file"
        fi
    done
else
    echo "Warning: Test directory $TEST_DIR not found"
fi

echo "=== Test Results ==="
echo "Output files in: $OUTPUT_DIR/"
echo ""
echo "To inspect a specific compilation:"
echo "  MiniImpCompiler -v -s -O test_ex/test_0.minimp output.risc"

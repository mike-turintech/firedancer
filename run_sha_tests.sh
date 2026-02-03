#!/bin/bash
# Focused SHA test script for validating AVX batch optimizations
# This specifically targets SHA-256 and SHA-512 implementations

set -e

BUILD_DIR="./build/native/gcc/unit-test"

echo "========================================"
echo "SHA Implementation Test Suite"
echo "Testing AVX Batch Optimizations"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if tests are built
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}Error: Build directory not found at $BUILD_DIR${NC}"
    echo "Please build the tests first with: make unit-test -j"
    exit 1
fi

# Function to run SHA test with detailed output
run_sha_test() {
    local test_name=$1
    local description=$2
    
    echo ""
    echo -e "${BLUE}=== $test_name - $description ===${NC}"
    
    if [ ! -f "$BUILD_DIR/$test_name" ]; then
        echo -e "${RED}✗ $test_name not found${NC}"
        return 1
    fi
    
    # Run test and capture output
    local output_file="/tmp/${test_name}_output.log"
    if $BUILD_DIR/$test_name --log-path /dev/stdout 2>&1 | tee "$output_file"; then
        echo ""
        echo -e "${GREEN}✓ $test_name completed successfully${NC}"
        
        # Extract performance metrics
        echo ""
        echo "Performance Metrics:"
        grep -E "Gbps|hash/s|ns/|MH/s|throughput" "$output_file" || echo "  No performance metrics found"
        
        # Extract batch test results
        echo ""
        echo "Batch Test Results:"
        grep -i "batch" "$output_file" | head -10 || echo "  No batch-specific output"
        
        # Check for CAVP results
        if grep -qi "cavp" "$output_file"; then
            echo ""
            echo "CAVP Test Vectors:"
            grep -i "cavp" "$output_file"
        fi
        
        return 0
    else
        echo ""
        echo -e "${RED}✗ $test_name FAILED${NC}"
        echo ""
        echo "Error output:"
        grep -i "fail\|error" "$output_file" | head -20
        return 1
    fi
}

# Run SHA tests
echo "Testing SHA Implementations:"
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

# SHA-1 (baseline)
if run_sha_test "test_sha1" "SHA-1 implementation"; then
    ((TESTS_PASSED++))
else
    ((TESTS_FAILED++))
fi

# SHA-256 (with AVX batch)
if run_sha_test "test_sha256" "SHA-256 with AVX batch optimization"; then
    ((TESTS_PASSED++))
else
    ((TESTS_FAILED++))
fi

# SHA-384 (variant of SHA-512)
if run_sha_test "test_sha384" "SHA-384 (SHA-512 variant)"; then
    ((TESTS_PASSED++))
else
    ((TESTS_FAILED++))
fi

# SHA-512 (with AVX batch - critical)
if run_sha_test "test_sha512" "SHA-512 with AVX batch optimization"; then
    ((TESTS_PASSED++))
else
    ((TESTS_FAILED++))
fi

echo ""
echo "========================================"
echo "Test Results Summary"
echo "========================================"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
fi
echo ""

# Recommendations
echo "========================================"
echo "Recommendations"
echo "========================================"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All SHA tests passed!${NC}"
    echo ""
    echo "Next steps for thorough validation:"
    echo ""
    echo "1. Run with CAVP test vectors (thousands of test cases):"
    echo "   make clean"
    echo "   CPPFLAGS='-DHAS_CAVP_TEST_VECTORS' make unit-test -j"
    echo "   ./run_sha_tests.sh"
    echo ""
    echo "2. Run fuzz tests to catch edge cases:"
    echo "   make fuzz_sha256_run  # 10 minute fuzz test"
    echo "   make fuzz_sha512_run  # 10 minute fuzz test"
    echo "   make fuzz_sha384_run  # 10 minute fuzz test"
    echo ""
    echo "3. Run stress tests with different batch sizes:"
    echo "   # These are included in the unit tests above"
    echo ""
else
    echo -e "${RED}⚠ Some tests failed!${NC}"
    echo ""
    echo "Critical: SHA test failures may indicate:"
    echo "  - Incorrect AVX batch implementation"
    echo "  - Message schedule computation errors"
    echo "  - Data alignment issues"
    echo ""
    echo "Review the error output above and check:"
    echo "  1. The sigma precomputation order (lines 244-252 in fd_sha512_batch_avx.c)"
    echo "  2. Message schedule dependencies"
    echo "  3. Test against reference implementation"
    echo ""
fi

echo "========================================"
echo ""

# Exit with error if tests failed
if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi

exit 0

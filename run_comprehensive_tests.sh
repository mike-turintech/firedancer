#!/bin/bash
# Comprehensive test script for SHA and cryptographic hash implementations
# This script runs all relevant tests for validating SHA-256/SHA-512 optimizations

set -e

BUILD_DIR="./build/native/gcc/unit-test"
TESTS_PASSED=0
TESTS_FAILED=0

echo "========================================"
echo "Comprehensive Cryptographic Test Suite"
echo "========================================"
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to run a test
run_test() {
    local test_name=$1
    echo ""
    echo "=== Running: $test_name ==="
    
    if [ ! -f "$BUILD_DIR/$test_name" ]; then
        echo -e "${YELLOW}WARNING: $test_name not found in $BUILD_DIR${NC}"
        echo "  You may need to build it first with: make unit-test"
        return
    fi
    
    if $BUILD_DIR/$test_name --log-path /dev/stdout 2>&1 | tee /tmp/${test_name}_output.log | grep -E "Gbps|hash/s|ns/|MH/s|K/s|throughput|pass"; then
        echo -e "${GREEN}✓ $test_name PASSED${NC}"
        ((TESTS_PASSED++))
    else
        if grep -qi "fail" /tmp/${test_name}_output.log; then
            echo -e "${RED}✗ $test_name FAILED${NC}"
            ((TESTS_FAILED++))
        else
            echo -e "${YELLOW}? $test_name status unclear${NC}"
        fi
    fi
}

echo "Part 1: SHA Family Tests (Critical for AVX optimizations)"
echo "--------------------------------------------------------"

# SHA tests - most critical for this scenario
run_test "test_sha1"
run_test "test_sha256"
run_test "test_sha384"
run_test "test_sha512"

echo ""
echo "Part 2: Other Hash and Cryptographic Tests"
echo "-------------------------------------------"

# Other hash tests from your original command
for test in test_blake3 test_lthash test_keccak256 test_murmur3 test_siphash13; do
    run_test "$test"
done

echo ""
echo "Part 3: Cryptographic Primitives Tests"
echo "---------------------------------------"

# Crypto primitives
for test in test_ed25519 test_chacha test_secp256k1 test_ristretto255 test_x25519; do
    run_test "$test"
done

echo ""
echo "Part 4: Protocol-Specific Tests"
echo "--------------------------------"

# Protocol tests
for test in test_poh test_bmtree test_shredder test_vm_interp test_pack; do
    run_test "$test"
done

echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
fi
echo ""

# Check for fuzz tests
echo "========================================"
echo "Additional Fuzz Tests (Optional)"
echo "========================================"
echo ""
echo "To run fuzz tests for SHA implementations:"
echo "  make fuzz_sha256_unit    # Run fuzz_sha256 on existing corpus"
echo "  make fuzz_sha384_unit    # Run fuzz_sha384 on existing corpus"
echo "  make fuzz_sha512_unit    # Run fuzz_sha512 on existing corpus"
echo ""
echo "To run fuzz tests in exploration mode (10 minutes each):"
echo "  make fuzz_sha256_run"
echo "  make fuzz_sha384_run"
echo "  make fuzz_sha512_run"
echo ""

# Check for CAVP support
echo "========================================"
echo "NIST CAVP Test Vectors (Recommended)"
echo "========================================"
echo ""
echo "To run comprehensive NIST CAVP validation:"
echo "  1. Rebuild with CAVP support:"
echo "     make clean"
echo "     CPPFLAGS='-DHAS_CAVP_TEST_VECTORS' make unit-test -j"
echo ""
echo "  2. Run tests with CAVP vectors:"
echo "     $BUILD_DIR/test_sha256 2>&1 | grep -i cavp"
echo "     $BUILD_DIR/test_sha384 2>&1 | grep -i cavp"
echo "     $BUILD_DIR/test_sha512 2>&1 | grep -i cavp"
echo ""
echo "CAVP test vectors include thousands of test cases from NIST"
echo "and are highly recommended for validating cryptographic implementations."
echo ""

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi

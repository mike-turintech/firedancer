# Testing Guide for SHA-256/SHA-512 Optimizations

This directory contains comprehensive test scripts for validating SHA implementations, particularly the AVX batch optimizations.

## Quick Start

### Build the tests first:
```bash
make unit-test -j
```

### Run focused SHA tests:
```bash
./run_sha_tests.sh
```

### Run comprehensive test suite:
```bash
./run_comprehensive_tests.sh
```

## Test Scripts

### 1. `run_sha_tests.sh` (Recommended for SHA optimization validation)

Focused test suite specifically for SHA implementations:
- **test_sha1** - SHA-1 baseline implementation
- **test_sha256** - SHA-256 with AVX batch optimization
- **test_sha384** - SHA-384 (SHA-512 variant)
- **test_sha512** - SHA-512 with AVX batch optimization (CRITICAL)

**Features:**
- Extracts and displays performance metrics (Gbps, throughput)
- Shows batch processing results
- Identifies CAVP test vector results
- Provides detailed pass/fail analysis
- Recommends next steps based on results

**Usage:**
```bash
./run_sha_tests.sh
```

### 2. `run_comprehensive_tests.sh`

Complete test suite including all cryptographic and hash implementations:

**Categories tested:**
- SHA family (sha1, sha256, sha384, sha512)
- Other hashes (blake3, keccak256, murmur3, siphash13, lthash)
- Cryptographic primitives (ed25519, chacha, secp256k1, ristretto255, x25519)
- Protocol-specific (poh, bmtree, shredder, vm_interp, pack)

**Usage:**
```bash
./run_comprehensive_tests.sh
```

## Tests You Should Run for SHA Optimization Validation

Based on your original test command, here are **additional tests** you were missing:

### 1. SHA-1 Test (Missing from your command)
```bash
./build/native/gcc/unit-test/test_sha1
```

### 2. Fuzz Tests (Important for edge cases)
```bash
# Build fuzz tests
make fuzz-test

# Run on existing corpus
make fuzz_sha256_unit
make fuzz_sha384_unit
make fuzz_sha512_unit

# Run in exploration mode (10 minutes each)
make fuzz_sha256_run
make fuzz_sha384_run  
make fuzz_sha512_run
```

### 3. NIST CAVP Test Vectors (Highly Recommended)

CAVP (Cryptographic Algorithm Validation Program) test vectors provide thousands of test cases from NIST:

```bash
# Rebuild with CAVP support
make clean
CPPFLAGS='-DHAS_CAVP_TEST_VECTORS' make unit-test -j

# Run SHA tests (will automatically include CAVP vectors)
./build/native/gcc/unit-test/test_sha256 2>&1 | grep -i cavp
./build/native/gcc/unit-test/test_sha384 2>&1 | grep -i cavp
./build/native/gcc/unit-test/test_sha512 2>&1 | grep -i cavp
```

**CAVP test files included:**
- `src/ballet/sha256/cavp/SHA256ShortMsg.rsp`
- `src/ballet/sha256/cavp/SHA256LongMsg.rsp`
- `src/ballet/sha256/cavp/SHA256Monte.rsp`
- `src/ballet/sha512/cavp/SHA384ShortMsg.rsp`
- `src/ballet/sha512/cavp/SHA384LongMsg.rsp`
- `src/ballet/sha512/cavp/SHA512ShortMsg.rsp`
- `src/ballet/sha512/cavp/SHA512LongMsg.rsp`
- `src/ballet/sha512/cavp/SHA512Monte.rsp`

## Why These Tests Matter for AVX Batch Optimizations

### Batch Processing Tests
Both `test_sha256` and `test_sha512` include specific tests for batch processing:
- Tests various batch sizes (1-24 messages)
- Validates AVX-optimized code paths
- Measures throughput improvements
- Ensures correctness with parallel processing

### Critical for Your Scenario
Given the potential ordering issue identified in `fd_sha512_batch_avx.c` (lines 244-252), it's essential to:

1. **Run unit tests** - Catch basic correctness issues
2. **Run CAVP vectors** - Validate against thousands of NIST test cases
3. **Run fuzz tests** - Find edge cases and corner conditions
4. **Check batch tests** - Ensure AVX optimizations work correctly

### Performance Metrics to Monitor
The test scripts extract these metrics from output:
- **Gbps** - Gigabits per second throughput
- **hash/s** - Hashes per second
- **ns/** - Nanoseconds per operation
- **MH/s** - Megahashes per second
- **K/s** - Kilobytes per second

## Understanding Test Output

### Successful Output Example:
```
=== test_sha512 - SHA-512 with AVX batch optimization ===
✓ test_sha512 completed successfully

Performance Metrics:
  ~2.345 Gbps Ethernet equiv throughput / core (sz 1024)
  ~3.456 Gbps Ethernet equiv throughput / core (batch_cnt 4 sz 1024)

Batch Test Results:
  Testing batch processing with 1-24 messages
  All batch tests passed
```

### Failed Output Example:
```
=== test_sha512 ===
✗ test_sha512 FAILED

Error output:
  FAIL (sz 1024)
  Expected: 44 1a e9 ca 41 7c c3 11 ...
  Got:      ff ff ff ff ff ff ff ff ...
```

## Troubleshooting

### If tests are not found:
```bash
# Build them first
make unit-test -j
```

### If you get "command not found":
```bash
# Make scripts executable
chmod +x run_sha_tests.sh run_comprehensive_tests.sh
```

### If you want to see all output (not just metrics):
```bash
# Run tests directly
./build/native/gcc/unit-test/test_sha512 --log-path /dev/stdout
```

## Additional Resources

- **Test source files:**
  - `src/ballet/sha256/test_sha256.c`
  - `src/ballet/sha512/test_sha512.c`
  - `src/ballet/sha512/test_sha384.c`

- **Implementation files:**
  - `src/ballet/sha256/fd_sha256_batch_avx.c`
  - `src/ballet/sha512/fd_sha512_batch_avx.c`

- **Fuzz test sources:**
  - `src/ballet/sha256/fuzz_sha256.c`
  - `src/ballet/sha512/fuzz_sha512.c`
  - `src/ballet/sha512/fuzz_sha384.c`

## Summary

Your original command was good but missing:
1. ✗ **test_sha1** - Should be included
2. ✗ **Fuzz tests** - Important for edge case validation
3. ✗ **CAVP vectors** - Essential for cryptographic validation

Use the provided scripts for comprehensive testing, or run this enhanced command:

```bash
# Enhanced test command
for test in test_sha1 test_sha256 test_sha384 test_sha512 test_blake3 test_lthash test_ed25519 test_keccak256 test_murmur3 test_siphash13 test_chacha test_poh test_bmtree test_secp256k1 test_ristretto255 test_x25519 test_shredder test_vm_interp test_pack; do 
  echo "=== $test ===" && ./build/native/gcc/unit-test/$test --log-path /dev/stdout 2>&1 | grep -E "Gbps|hash/s|ns/|MH/s|K/s|throughput|pass|FAIL"; 
done
```

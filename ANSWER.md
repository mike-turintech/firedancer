# Answer: Additional Tests You Should Run

## Your Current Test Command
You're running this command:
```bash
for test in test_blake3 test_sha512 test_sha256 test_sha384 test_lthash test_ed25519 test_keccak256 test_murmur3 test_siphash13 test_chacha test_poh test_bmtree test_secp256k1 test_ristretto255 test_x25519 test_shredder test_vm_interp test_pack; do 
  echo "=== $test ===" && ./build/native/gcc/unit-test/$test --log-path /dev/stdout 2>&1 | grep -E "Gbps|hash/s|ns/|MH/s|K/s|throughput"; 
done
```

## Missing Tests You Should Add

### 1. test_sha1 (Missing SHA test)
**Why:** You're testing SHA-256, SHA-384, and SHA-512 but not SHA-1. While SHA-1 is deprecated for cryptographic use, testing it ensures the SHA family implementations are consistent.

**Add to your command:**
```bash
test_sha1
```

### 2. Fuzz Tests (Critical for Edge Cases)
**Why:** Fuzz testing finds edge cases and corner conditions that unit tests might miss. Essential for cryptographic implementations.

**Run these separately:**
```bash
make fuzz_sha256_unit    # Test on existing corpus
make fuzz_sha384_unit
make fuzz_sha512_unit

# Or run in exploration mode (10 minutes each):
make fuzz_sha256_run
make fuzz_sha384_run
make fuzz_sha512_run
```

### 3. NIST CAVP Test Vectors (Highly Recommended)
**Why:** These are official NIST test vectors with thousands of test cases. If your SHA implementation passes CAVP, it's validated against the standard.

**How to run:**
```bash
# One-time setup: rebuild with CAVP support
make clean
CPPFLAGS='-DHAS_CAVP_TEST_VECTORS' make unit-test -j

# Then run your tests as normal - CAVP tests will be included
./build/native/gcc/unit-test/test_sha256 2>&1 | grep -i cavp
./build/native/gcc/unit-test/test_sha512 2>&1 | grep -i cavp
./build/native/gcc/unit-test/test_sha384 2>&1 | grep -i cavp
```

## Updated Command

### Option 1: Enhanced version of your command
```bash
for test in test_sha1 test_blake3 test_sha512 test_sha256 test_sha384 test_lthash test_ed25519 test_keccak256 test_murmur3 test_siphash13 test_chacha test_poh test_bmtree test_secp256k1 test_ristretto255 test_x25519 test_shredder test_vm_interp test_pack; do 
  echo "=== $test ===" && ./build/native/gcc/unit-test/$test --log-path /dev/stdout 2>&1 | grep -E "Gbps|hash/s|ns/|MH/s|K/s|throughput|pass|FAIL"; 
done
```

### Option 2: Use the provided scripts (easier)
```bash
# Just run this:
./run_sha_tests.sh          # For focused SHA testing
# or
./run_comprehensive_tests.sh # For all tests
```

## Why This Matters for Your Scenario

Given the SHA-512 AVX batch optimization context:

1. **Correctness First:** The batch optimizations involve complex message schedule precomputation. CAVP vectors catch subtle bugs.

2. **Edge Cases:** Fuzz tests will find weird input sizes and patterns that might break the optimized code paths.

3. **Completeness:** Testing SHA-1 ensures the overall SHA infrastructure is solid.

4. **Performance Validation:** The unit tests include batch performance tests that measure throughput improvements from AVX optimizations.

## Quick Reference

| Test | What | Why | How |
|------|------|-----|-----|
| test_sha1 | SHA-1 unit test | Complete SHA family coverage | Add to your command |
| Fuzz tests | Random input testing | Find edge cases | `make fuzz_sha*_run` |
| CAVP vectors | NIST official tests | Cryptographic validation | Rebuild with `-DHAS_CAVP_TEST_VECTORS` |
| Batch tests | AVX optimization tests | Already in unit tests | Check output for "batch" |

## Summary

**Yes**, there are more tests you should run:
1. ✓ Add **test_sha1** to your command
2. ✓ Run **fuzz tests** separately  
3. ✓ Run with **CAVP test vectors** for complete validation

The scripts I've provided (`run_sha_tests.sh` and `run_comprehensive_tests.sh`) handle all of this automatically with nice formatted output.

See `TESTING.md` for complete documentation.

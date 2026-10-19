# ABI Encoder Demo

A hands-on demo of **`abi.encodePacked()`** and `keccak256` in real DeFi patterns: deterministic pool IDs, trading and yield position identifiers, limit order hashes, swap paths, flash loan payloads and staking pool configs. Each function mirrors a technique used by protocols like Uniswap, with tests that verify the exact byte layout produced.

> This is a demo project for learning purposes, so it has no deployed instances.

Built with [Foundry](https://book.getfoundry.sh/), with full test coverage and a GitHub Actions CI pipeline.

## How it works

The project is a single stateless contract:

- [`ABIEncoderDemo`](https://github.com/davidvp-dev/abi-encoding-demo/blob/main/src/ABIEncoderDemo.sol): a collection of `external` functions that pack typed inputs into compact byte strings (`abi.encodePacked`) and, where an identifier is needed, hash them with `keccak256`. There is no storage and no access control, so every function is a `pure` or `view` helper.

The functions group into two ideas:

- **Hashed identifiers** — fixed-size inputs are packed and hashed into a unique `bytes32` ID: pools, trading positions, limit orders and yield positions.
- **Packed payloads** — inputs are packed into raw `bytes` ready to be sent or decoded off-chain: swap data, flash loan data and staking pool configs.

Two patterns worth highlighting:

- **Order-independent pool IDs:** `createPoolIdentifier` sorts the two token addresses before hashing, so `(A, B)` and `(B, A)` always produce the same ID — the same approach Uniswap uses to avoid duplicate pools.
- **Domain separation tags:** limit orders, yield positions and flash loan data append a version string (`LIMIT_ORDER_V1`, `YIELD_POSITION`, `FLASH_LOAN_V1`) to the packed data, so identical inputs encoded for different purposes never produce the same hash.

**Good to know:** `abi.encodePacked` does not pad values or add length information, so packing several *dynamic-length* values (arrays, `bytes`, `string`) next to each other can create ambiguous encodings and hash collisions. In this demo, every hashed identifier is built from fixed-size fields; for hashed data with multiple dynamic inputs, `abi.encode` is the safer choice.

## Execution example

Since this is a demo, it is meant to be run locally with [Anvil](https://book.getfoundry.sh/anvil/):

```shell
# 1. Start a local node
anvil

# 2. Deploy the contract
forge create src/ABIEncoderDemo.sol:ABIEncoderDemo --rpc-url http://127.0.0.1:8545 --private-key <PRIVATE_KEY> --broadcast

# 3. Compute a pool identifier (the token order does not matter)
cast call <DEMO_ADDRESS> "createPoolIdentifier(address,address,uint24)(bytes32)" <TOKEN_A> <TOKEN_B> 3000 --rpc-url http://127.0.0.1:8545
```

## Testing

The suite in [`test/ABIEncoderDemoTest.t.sol`](https://github.com/davidvp-dev/abi-encoding-demo/blob/main/test/ABIEncoderDemoTest.t.sol) rebuilds the expected byte strings and hashes independently and compares them against the contract's output. It covers:

- Pool IDs being identical for both token orders and different across fee tiers.
- Exact encoding and hash of trading positions, limit orders, yield positions, flash loan data and staking pool configs.
- Swap data encoding, plus the revert when path and amount arrays differ in length.

To run the tests:

```shell
forge test
```

To check coverage:

```shell
forge coverage
```

| File | % Lines | % Statements | % Branches | % Funcs |
|---|---|---|---|---|
| `src/ABIEncoderDemo.sol` | 100.00% (24/24) | 100.00% (22/22) | 100.00% (2/2) | 100.00% (7/7) |
| **Total** | **100.00% (24/24)** | **100.00% (22/22)** | **100.00% (2/2)** | **100.00% (7/7)** |

## License

MIT — see the SPDX identifier in the contract source.
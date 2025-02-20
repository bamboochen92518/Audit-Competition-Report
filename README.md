# Audit Competition Report

### 2025-02-datingdapp

#### Test Command

```bash
$ forge test --mc SoulboundProfileNFTTest
```

#### Competition Link

You can view the competition details here: [2025-02-datingdapp Competition](https://codehawks.cyfrin.io/c/2025-02-datingdapp).

#### My Findings

I have documented my findings here: 

### 2025-01-liquid-ron

#### Test Command

```bash
$ forge test --mc LiquidRonTest
```

#### Competition Link

You can view the competition details here: [2025-01-liquid-ron Competition](https://code4rena.com/audits/2025-01-liquid-ron).

#### My Findings

I did not identify any bugs in this competition. 😢

### 2025-01-diva

#### Test Command

```bash
$ forge test --mc AaveDIVAWrapperTest
```

#### Competition Link

You can view the competition details here: [2025-01-diva Competition](https://codehawks.cyfrin.io/c/2025-01-diva).

#### My Findings

I have documented my findings here: [Audit Findings - AaveDIVAWrapper](https://github.com/bamboochen92518/Audit-Competition-Report/tree/main/findings/2025-01-diva/bambooboo-Aave-DIVA-Wrapper.md). 

### 2025-01-pieces-protocol

#### Test Command

```bash
$ forge test --mc TokenDividerTest
```

#### Competition Link

You can view the competition details here: [2025-01-pieces-protocol Competition](https://codehawks.cyfrin.io/c/2025-01-pieces-protocol).

#### My Findings

I have documented my findings here: [Audit Findings - PiecesProtocol](https://github.com/bamboochen92518/Audit-Competition-Report/tree/main/findings/2025-01-pieces-protocol/bambooboo-Pieces-Protocol.md). 

### 2025-01-benqi

#### Test Command

I did not complete the Foundry test in this competition.

#### Competition Link

You can view the competition details here: [2025-01-benqi Competition](https://codehawks.cyfrin.io/c/2025-01-benqi).

#### My Findings

I have documented my findings here: [Audit Findings - Benqi](https://github.com/bamboochen92518/Audit-Competition-Report/tree/main/findings/2025-01-benqi/bambooboo-Ignite.md). 

---

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

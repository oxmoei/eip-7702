# BatchCallAndSponsor

一个使用 EIP-7702 演示账户抽象和赞助交易执行的教育项目。本项目使用 Foundry 进行部署、脚本编写和测试。

## 概述

`BatchCallAndSponsor` 合约通过验证对 nonce 和批量调用数据的签名来启用批量调用执行。它支持：
- **直接执行**：由智能账户本身执行。
- **赞助执行**：通过链下签名（由赞助者提供）。

通过每次批量执行后递增的内部 nonce 提供重放保护。

## 功能特性

- 批量交易执行
- 使用 ECDSA 进行链下签名验证
- 通过 nonce 递增提供重放保护
- 支持 ETH 和 ERC-20 代币转账

## 前置要求

- [Foundry](https://github.com/foundry-rs/foundry)
- Solidity ^0.8.20

## 运行项目

### 步骤 1：安装 Foundry

```sh
curl -L https://foundry.paradigm.xyz | bash
git clone 
cd eip-7702
```

### 步骤 2：安装包并创建重映射文件

```sh
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
forge remappings > remappings.txt
```

### 步骤 3：运行本地网络

在终端中运行以下命令以启动带有 Prague 硬分叉的本地网络。

```bash
anvil --hardfork prague
```

### 步骤 4：构建合约

在另一个终端中，运行以下命令来构建合约。

```bash
forge build
```

### 步骤 5：运行测试用例

构建合约后，运行以下命令来运行测试用例。如果您想显示所有测试的堆栈跟踪，请使用 `-vvvv` 标志而不是 `-vvv`。

```bash
forge test -vvv
```

输出应该如下所示：

```bash
Ran 4 tests for test/BatchCallAndSponsor.t.sol:BatchCallAndSponsorTest
[PASS] testDirectExecution() (gas: 128386)
Logs:
  Sending 1 ETH from Alice to Bob and transferring 100 tokens to Bob in a single transaction

[PASS] testReplayAttack() (gas: 114337)
Logs:
  Test replay attack: Reusing the same signature should revert.

[PASS] testSponsoredExecution() (gas: 110461)
Logs:
  Sending 1 ETH from Alice to a random address while the transaction is sponsored by Bob

[PASS] testWrongSignature() (gas: 37077)
Logs:
  Test wrong signature: Execution should revert with 'Invalid signature'.

Suite result: ok. 4 passed; 0 failed; 0 skipped;
```

### 步骤 6：运行脚本

现在您已经设置了项目，是时候运行部署脚本了。此脚本部署合约、铸造代币，并测试批量执行和赞助执行功能。

我们使用以下命令：
- **`--broadcast`**：将交易广播到您的本地网络。
- **`--rpc-url 127.0.0.1:8545`**：连接到您的本地网络。
- **`--tc BatchCallAndSponsorScript`**：指定脚本的目标合约。

```bash
forge script ./script/BatchCallAndSponsor.s.sol --tc BatchCallAndSponsorScript --broadcast --rpc-url 127.0.0.1:8545
```

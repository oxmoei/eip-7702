## Foundry

**Foundry 是一个用 Rust 编写的极速、便携且模块化的以太坊应用程序开发工具包。**

Foundry 包含以下组件：

-   **Forge**: 以太坊测试框架（类似于 Truffle、Hardhat 和 DappTools）。
-   **Cast**: 与 EVM 智能合约交互、发送交易和获取链上数据的瑞士军刀工具。
-   **Anvil**: 本地以太坊节点，类似于 Ganache、Hardhat Network。
-   **Chisel**: 快速、实用且详细的 Solidity REPL。

## 文档

https://book.getfoundry.sh/

## 使用方法

### 构建

```shell
$ forge build
```

### 测试

```shell
$ forge test
```

### 格式化

```shell
$ forge fmt
```

### Gas 快照

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### 部署

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### 帮助

```shell
$ forge --help
$ anvil --help
$ cast --help
```

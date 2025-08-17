# EIP-7702 智能账户合约

一个完整的 EIP-7702 智能账户实现，支持 EOA 临时升级为智能账户并执行批量交易，包括标准批量交易和自定义hex数据批量交易功能。

## 🎯 项目概述

EIP-7702 允许普通 EOA（Externally Owned Account）临时升级为智能账户，执行批量操作后自动恢复到 EOA 状态。本项目提供了完整的实现，包括标准批量交易和自定义hex数据批量交易功能。

## 🏗️ 核心特性

### 基础功能
- ✅ **EOA 临时升级** - 将普通账户临时升级为智能账户
- ✅ **批量交易执行** - 支持一次性执行多个交易
- ✅ **签名验证** - 使用 ECDSA 签名确保安全性
- ✅ **防重放攻击** - 通过 nonce 机制防止重放
- ✅ **自动状态恢复** - 执行完成后自动恢复到 EOA 状态

### 标准批量交易功能
- ✅ **标准交易格式** - 支持标准的 to/value/data 交易格式
- ✅ **ABI 解析** - 自动解析和显示函数调用信息
- ✅ **安全验证** - 内置地址白名单和金额限制
- ✅ **环境配置** - 通过环境变量灵活配置

### Hex 批量交易功能
- ✅ **自定义Hex数据** - 支持任意hex格式的交易数据
- ✅ **合约调用支持** - 支持智能合约函数调用
- ✅ **ETH转账** - 支持简单的ETH转账
- ✅ **安全验证** - 内置地址白名单和金额限制
- ✅ **环境配置** - 通过环境变量灵活配置

## 📁 项目结构

```
eip-7702/
├── src/
│   └── EIP7702SmartAccount.sol        # 核心智能账户合约
├── scripts/
│   ├── eip7702-standard-batch.js      # 标准批量交易脚本
│   └── eip7702-hex-batch.js           # Hex批量交易脚本
├── call_data/
│   ├── standard-batch-config.json     # 标准批量交易配置
│   ├── hex-batch-config.json          # Hex批量交易配置
│   ├── STANDARD_BATCH_CONFIG_GUIDE.md # 标准批量交易配置指南
│   └── HEX_BATCH_CONFIG_GUIDE.md      # Hex批量交易配置指南
├── deploy.sh                          # 部署脚本
├── foundry.toml                       # Foundry 配置
├── remappings.txt                     # 依赖重映射
├── package.json                       # Node.js 项目配置
├── CONTRACT_VERIFICATION_GUIDE.md     # 合约验证（开源）指南
├── .env                               # 环境变量配置
├── .gitignore                         # Git 忽略文件
└── README.md                          # 项目说明
```

## 🚀 快速开始

### 1. 环境准备

```bash
# 安装 Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 安装 Foundry 依赖
forge install

# 安装 Node.js 依赖
npm install
```

### 2. 环境配置

创建 `.env` 文件并配置以下环境变量：

**注意**: 请确保将 `PRIVATE_KEY` 替换为您的实际私钥，将 `RPC_URL` 替换为您的实际 RPC 端点地址。

```env
# 基础配置
PRIVATE_KEY=0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
RPC_URL=https://bsc-testnet.infura.io/v3/YOUR_INFURA_PROJECT_ID

# 实现合约地址（运行 deploy.sh 后会自动添加）
SMART_ACCOUNT_ADDRESS=

# 功能开关
ENABLE_STANDARD_BATCH=true
ENABLE_HEX_BATCH=true

# Gas 配置
GAS_LIMIT=300000
GAS_PRICE_STRATEGY=auto
TRANSACTION_TIMEOUT=300
MAX_RETRIES=3

# 交易限制
MAX_SINGLE_TRANSACTION_VALUE=1000000000000000000
MAX_BATCH_TOTAL_VALUE=5000000000000000000

# 安全配置
ENABLE_ADDRESS_WHITELIST=false
ALLOWED_TARGETS=

# 配置文件路径
STANDARD_BATCH_CONFIG_FILE=call_data/standard-batch-config.json
HEX_BATCH_CONFIG_FILE=call_data/hex-batch-config.json

# 日志配置
LOG_LEVEL=info
```

### 3. 部署合约

```bash
# 运行部署脚本
chmod +x deploy.sh
./deploy.sh
```

### 4. 执行批量交易

```bash
# 执行标准批量交易
npm run standard

# 执行 Hex 批量交易
npm run hex
```

## 📦 依赖项

### Foundry 依赖项
- `@openzeppelin/contracts` - OpenZeppelin 智能合约库
- `forge-std` - Foundry 标准库

### Node.js 依赖项
- `viem` - 以太坊客户端库
- `dotenv` - 环境变量管理
- `chalk` - 终端颜色输出

## 🔧 核心合约

### EIP7702SmartAccount.sol

主要的智能账户合约，包含以下功能：

#### 基础功能
- **validateAuthorization** - 验证 EIP-7702 授权签名
- **executeBatchWithAuthorization** - 执行批量交易（带授权）
- **executeWithAuthorization** - 执行单笔交易（带授权）
- **executeBatch** - 直接执行批量交易
- **execute** - 直接执行单笔交易

#### Hex 批量交易功能
- **executeHexBatchWithAuthorization** - 执行hex批量交易（带授权）
- **executeHexWithAuthorization** - 执行单笔hex交易（带授权）
- **executeHexBatch** - 直接执行hex批量交易
- **executeHex** - 直接执行单笔hex交易

## 🎯 批量交易使用

### 🔴 标准批量交易

#### 1. 配置文件

编辑 `call_data/standard-batch-config.json`：

```json
{
  "transactions": [
    {
      "to": "0xcb98643b8786950F0461f3B0edf99D88F274574D",
      "value": "1000000000000000",
      "data": "0x",
      "description": "向地址1发送0.001 ETH"
    },
    {
      "to": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
      "value": "0",
      "data": "0xa9059cbb000000000000000000000000cb98643b8786950F0461f3B0edf99D88F274574D0000000000000000000000000000000000000000000000000000000000000064",
      "description": "ERC20代币转账调用"
    }
  ],
  "settings": {
    "maxSingleTransactionValue": "1000000000000000000",
    "maxBatchTotalValue": "5000000000000000000",
    "enableAddressWhitelist": false,
    "allowedTargets": []
  }
}
```

#### 2. 执行交易

```bash
npm run standard
```

### 🔴 Hex 批量交易

#### 1. 配置文件

编辑 `call_data/hex-batch-config.json`：

```json
{
  "transactions": [
    {
      "target": "0xcb98643b8786950F0461f3B0edf99D88F274574D",
      "value": "1000000000000000",
      "hexData": "0x",
      "isContractCall": false,
      "description": "向地址1发送0.001 ETH"
    },
    {
      "target": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
      "value": "0",
      "hexData": "0xa9059cbb000000000000000000000000cb98643b8786950F0461f3B0edf99D88F274574D0000000000000000000000000000000000000000000000000000000000000064",
      "isContractCall": true,
      "description": "ERC20代币转账调用"
    }
  ],
  "settings": {
    "maxSingleTransactionValue": "1000000000000000000",
    "maxBatchTotalValue": "5000000000000000000",
    "enableAddressWhitelist": false,
    "allowedTargets": []
  }
}
```

#### 2. 执行交易

```bash
npm run hex
```

详细配置说明请参考：
- [标准批量交易配置指南](call_data/STANDARD_BATCH_CONFIG_GUIDE.md)
- [Hex 批量交易配置指南](call_data/HEX_BATCH_CONFIG_GUIDE.md)

## 🔒 安全特性

- **私钥安全** - 通过环境变量管理，不在代码中硬编码
- **地址验证** - 支持白名单机制，防止意外转账
- **金额限制** - 设置合理的交易金额上限
- **错误处理** - 完整的错误回滚和异常处理
- **测试网络** - 建议先在测试网络上验证
- **Gas 优化** - 自动 Gas 估算和策略选择

## 📋 可用命令

```bash
# 部署合约
npm run deploy

# 执行标准批量交易
npm run standard

# 执行 Hex 批量交易
npm run hex
```

## 🐛 故障排除

### 常见问题

1. **配置错误**
   ```
   错误: 请设置有效的 PRIVATE_KEY
   解决: 检查.env文件中的私钥配置
   ```

2. **功能未启用**
   ```
   错误: 标准批量交易功能未启用，请设置 ENABLE_STANDARD_BATCH=true
   解决: 在.env文件中设置相应的功能开关为true
   ```

3. **网络连接问题**
   ```
   错误: 无法连接到RPC节点
   解决: 检查RPC_URL配置和网络连接
   ```

4. **Gas不足**
   ```
   错误: Gas不足
   解决: 增加GAS_LIMIT或检查账户余额
   ```

5. **配置文件错误**
   ```
   错误: 配置文件不存在或格式错误
   解决: 检查call_data目录下的配置文件是否存在且格式正确
   ```

6. **语法错误**
   ```
   错误: SyntaxError: missing ) after argument list
   解决: 检查脚本文件中的语法错误，确保所有括号匹配
   ```

7. **环境变量缺失**
   ```
   错误: 环境变量未设置
   解决: 确保.env文件存在且包含所有必需的配置项
   ```

## 📚 相关链接

- [EIP-7702 规范](https://eips.ethereum.org/EIPS/eip-7702)
- [OpenZeppelin 合约](https://openzeppelin.com/contracts/)
- [Viem 文档](https://viem.sh/)
- [Foundry 文档](https://book.getfoundry.sh/)

## 💬 联系与支持
- Telegram: [t.me/cryptostar210](https://t.me/cryptostar210)
- 请我喝杯☕：**0xd328426a8e0bcdbbef89e96a91911eff68734e84** ▋**5LmGJmv7Lbjh9K1gEer47xSHZ7mDcihYqVZGoPMRo89s**
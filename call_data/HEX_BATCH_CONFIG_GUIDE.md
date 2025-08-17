# Hex 批量交易配置文件指南

## 概述

Hex 批量交易现在支持从 JSON 文件加载配置，这样可以避免在 `.env` 文件中处理复杂的 JSON 格式，并提供更好的配置管理。

## 配置文件结构

### 基本结构

```json
{
  "transactions": [
    {
      "target": "0x...",
      "value": "1000000000000000",
      "hexData": "0x...",
      "isContractCall": false,
      "description": "交易描述"
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

### 字段说明

#### transactions 数组

每个交易对象包含以下字段：

- **target** (必需): 目标合约地址
- **value** (必需): ETH 数量，以 wei 为单位（字符串格式）
- **hexData** (可选): 十六进制调用数据，默认为 "0x"
- **isContractCall** (可选): 是否为合约调用，默认为 false
- **description** (可选): 交易描述，用于日志输出

#### settings 对象

- **maxSingleTransactionValue**: 最大单笔交易金额（wei，字符串格式）
- **maxBatchTotalValue**: 最大批量交易总金额（wei，字符串格式）
- **enableAddressWhitelist**: 是否启用地址白名单验证
- **allowedTargets**: 允许的目标地址数组

## 配置示例

### 示例 1: 简单的 ETH 转账

```json
{
  "transactions": [
    {
      "target": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
      "value": "1000000000000000000",
      "hexData": "0x",
      "isContractCall": false,
      "description": "向地址1发送1 ETH"
    },
    {
      "target": "0xcb98643b8786950F0461f3B0edf99D88F274574D",
      "value": "2000000000000000000",
      "hexData": "0x",
      "isContractCall": false,
      "description": "向地址2发送2 ETH"
    }
  ],
  "settings": {
    "maxSingleTransactionValue": "5000000000000000000",
    "maxBatchTotalValue": "10000000000000000000",
    "enableAddressWhitelist": false,
    "allowedTargets": []
  }
}
```

### 示例 2: 混合交易（ETH 转账 + 合约调用）

```json
{
  "transactions": [
    {
      "target": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
      "value": "1000000000000000000",
      "hexData": "0x",
      "isContractCall": false,
      "description": "ETH 转账"
    },
    {
      "target": "0xA0b86a33E6441b8c4C8C8C8C8C8C8C8C8C8C8C8C",
      "value": "0",
      "hexData": "0xa9059cbb000000000000000000000000cb98643b8786950F0461f3B0edf99D88F274574D000000000000000000000000000000000000000000000000d3c21bcecceda0000000",
      "isContractCall": true,
      "description": "ERC20 代币转账"
    }
  ],
  "settings": {
    "maxSingleTransactionValue": "2000000000000000000",
    "maxBatchTotalValue": "5000000000000000000",
    "enableAddressWhitelist": true,
    "allowedTargets": [
      "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
      "0xA0b86a33E6441b8c4C8C8C8C8C8C8C8C8C8C8C8C"
    ]
  }
}
```

### 示例 3: 复杂的合约交互

```json
{
  "transactions": [
    {
      "target": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
      "value": "0",
      "hexData": "0x095ea7b3000000000000000000000000b5c56d5a06a51271523247153b64afacd583a64a000000000000000000000000000000000000000000000000d3c21bcecceda0000000",
      "isContractCall": true,
      "description": "授权 USDC 代币"
    },
    {
      "target": "0xA0b86a33E6441b8c4C8C8C8C8C8C8C8C8C8C8C8C",
      "value": "0",
      "hexData": "0x23b872dd000000000000000000000000742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6000000000000000000000000cb98643b8786950F0461f3B0edf99D88F274574D000000000000000000000000000000000000000000000000d3c21bcecceda0000000",
      "isContractCall": true,
      "description": "转移 USDC 代币"
    }
  ],
  "settings": {
    "maxSingleTransactionValue": "0",
    "maxBatchTotalValue": "0",
    "enableAddressWhitelist": true,
    "allowedTargets": [
      "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
      "0xA0b86a33E6441b8c4C8C8C8C8C8C8C8C8C8C8C8C"
    ]
  }
}
```

## 使用方法

### 1. 创建配置文件

将配置文件保存为 `hex-batch-config.json`（或自定义名称）。

### 2. 设置环境变量

在 `.env` 文件中设置：

```bash
# 启用 hex 批量交易
ENABLE_HEX_BATCH=true

# 指定配置文件路径（可选，默认为 call_data/hex-batch-config.json）
HEX_BATCH_CONFIG_FILE=call_data/hex-batch-config.json
```

### 3. 运行脚本

```bash
# 直接执行
node scripts/eip7702-hex-batch.js

# 或者使用 npm 脚本（如果已配置）
npm run hex
```

## 优势

1. **更好的格式**: JSON 格式比环境变量中的字符串更易读和维护
2. **复杂配置**: 支持更复杂的配置结构
3. **版本控制**: 配置文件可以单独版本控制
4. **多环境**: 可以为不同环境创建不同的配置文件
5. **验证**: JSON 格式有更好的语法验证

## 注意事项

1. **文件路径**: 配置文件路径相对于项目根目录
2. **权限**: 确保脚本有读取配置文件的权限
3. **格式**: 确保 JSON 格式正确，可以使用在线 JSON 验证工具
4. **备份**: 重要配置建议备份
5. **安全**: 不要将包含敏感信息的配置文件提交到版本控制系统

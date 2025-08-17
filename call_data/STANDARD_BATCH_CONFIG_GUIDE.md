# EIP-7702 标准批量交易配置指南

## 📋 概述

标准批量交易功能允许您执行多个标准交易调用，包括 ETH 转账和智能合约调用。与 Hex 批量交易不同，标准批量交易使用更简单的数据结构，更适合常见的批量操作场景。

## 🔧 环境配置

### 1. 启用标准批量交易

在 `.env` 文件中添加以下配置：

```bash
# 启用标准批量交易
ENABLE_STANDARD_BATCH=true

# 标准批量交易配置文件路径 (可选，默认为 call_data/standard-batch-config.json)
STANDARD_BATCH_CONFIG_FILE=call_data/standard-batch-config.json
```

### 2. 可选配置项

```bash
# 最大单笔交易金额 (默认: 1 ETH)
MAX_SINGLE_TRANSACTION_VALUE=1000000000000000000

# 最大批量交易总金额 (默认: 5 ETH)
MAX_BATCH_TOTAL_VALUE=5000000000000000000

# 启用地址白名单 (默认: false)
ENABLE_ADDRESS_WHITELIST=false

# 允许的目标地址 (逗号分隔)
ALLOWED_TARGETS=0x1234...,0x5678...
```

## 📄 配置文件格式

### 基本结构

```json
{
  "transactions": [
    {
      "target": "0x目标地址",
      "value": "交易金额(wei)",
      "data": "调用数据",
      "description": "交易描述"
    }
  ],
  "settings": {
    "maxSingleTransactionValue": "最大单笔交易金额",
    "maxBatchTotalValue": "最大批量交易总金额",
    "enableAddressWhitelist": false,
    "allowedTargets": []
  }
}
```

### 字段说明

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `target` | string | ✅ | 目标合约或地址 |
| `value` | string | ✅ | 发送的 ETH 数量（wei） |
| `data` | string | ❌ | 调用数据（默认为 "0x"） |
| `abi` | object | ❌ | 函数 ABI 定义 |
| `params` | array | ❌ | 函数参数数组 |
| `description` | string | ❌ | 交易描述 |

**注意**: 如果提供了 `abi` 和 `params`，脚本会自动编码调用数据。如果只提供了 `data`，则直接使用该数据。

### 配置示例

#### 1. ETH 转账示例

```json
{
  "transactions": [
    {
      "target": "0xcb98643b8786950F0461f3B0edf99D88F274574D",
      "value": "1000000000000000",
      "data": "0x",
      "description": "向地址1发送0.001 ETH"
    },
    {
      "target": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
      "value": "2000000000000000",
      "data": "0x",
      "description": "向地址2发送0.002 ETH"
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

#### 2. ERC20 代币操作示例（使用 ABI）

```json
{
  "transactions": [
    {
      "target": "0x6B175474E89094C44Da98b954EedeAC495271d0F",
      "value": "0",
      "abi": {
        "name": "approve",
        "type": "function",
        "inputs": [
          {
            "name": "spender",
            "type": "address"
          },
          {
            "name": "amount",
            "type": "uint256"
          }
        ],
        "outputs": [
          {
            "name": "",
            "type": "bool"
          }
        ],
        "stateMutability": "nonpayable"
      },
      "params": [
        "0xb5c56d5a06a51271523247153b64afacd583a64a",
        "1000000000000000000000"
      ],
      "description": "DAI 代币授权"
    },
    {
      "target": "0xA0b86a33E6441b8C4C8C8C8C8C8C8C8C8C8C8C8",
      "value": "0",
      "abi": {
        "name": "transfer",
        "type": "function",
        "inputs": [
          {
            "name": "to",
            "type": "address"
          },
          {
            "name": "amount",
            "type": "uint256"
          }
        ],
        "outputs": [
          {
            "name": "",
            "type": "bool"
          }
        ],
        "stateMutability": "nonpayable"
      },
      "params": [
        "0xcb98643b8786950F0461f3B0edf99D88F274574D",
        "100"
      ],
      "description": "ERC20 代币转账"
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

#### 3. 混合操作示例（ABI + 直接数据）

```json
{
  "transactions": [
    {
      "target": "0xcb98643b8786950F0461f3B0edf99D88F274574D",
      "value": "1000000000000000",
      "data": "0x",
      "description": "ETH 转账"
    },
    {
      "target": "0x6B175474E89094C44Da98b954EedeAC495271d0F",
      "value": "0",
      "abi": {
        "name": "approve",
        "type": "function",
        "inputs": [
          {
            "name": "spender",
            "type": "address"
          },
          {
            "name": "amount",
            "type": "uint256"
          }
        ],
        "outputs": [
          {
            "name": "",
            "type": "bool"
          }
        ],
        "stateMutability": "nonpayable"
      },
      "params": [
        "0xb5c56d5a06a51271523247153b64afacd583a64a",
        "1000000000000000000000"
      ],
      "description": "代币授权（使用ABI）"
    },
    {
      "target": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
      "value": "500000000000000",
      "data": "0x",
      "description": "另一个 ETH 转账"
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

#### 3. 混合操作示例

```json
{
  "transactions": [
    {
      "target": "0xcb98643b8786950F0461f3B0edf99D88F274574D",
      "value": "1000000000000000",
      "data": "0x",
      "description": "ETH 转账"
    },
    {
      "target": "0x6B175474E89094C44Da98b954EedeAC495271d0F",
      "value": "0",
      "data": "0x095ea7b3000000000000000000000000b5c56d5a06a51271523247153b64afacd583a64a000000000000000000000000000000000000000000000000d3c21bcecceda0000000",
      "description": "代币授权"
    },
    {
      "target": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
      "value": "500000000000000",
      "data": "0x",
      "description": "另一个 ETH 转账"
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

## 🚀 使用方法

### 1. 执行脚本

```bash
# 直接执行
node scripts/eip7702-standard-batch.js

# 或者使用 npm 脚本（如果已配置）
npm run standard
```

### 2. 执行流程

1. **配置验证** - 检查环境变量和配置文件
2. **网络检测** - 自动识别网络信息
3. **账户状态检查** - 验证 EOA 状态
4. **授权生成** - 创建 EIP-7702 授权签名
5. **交易准备** - 加载和验证批量交易
6. **交易执行** - 发送批量交易到区块链
7. **确认等待** - 等待交易确认
8. **状态检查** - 验证最终状态

## 🔒 安全特性

### 1. 金额限制

- **单笔交易限制**: 防止单笔交易金额过大
- **批量总金额限制**: 防止批量交易总金额过大
- **可配置限制**: 通过配置文件灵活设置

### 2. 地址白名单

```json
{
  "settings": {
    "enableAddressWhitelist": true,
    "allowedTargets": [
      "0xcb98643b8786950F0461f3B0edf99D88F274574D",
      "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6"
    ]
  }
}
```

### 3. 交易验证

- **地址格式验证**: 确保目标地址格式正确
- **数据格式验证**: 验证调用数据格式
- **金额验证**: 检查交易金额是否在允许范围内

## 📊 与 Hex 批量交易的区别

| 特性 | 标准批量交易 | Hex 批量交易 |
|------|-------------|-------------|
| 数据结构 | `Call` 结构体 | `HexBatchTransaction` 结构体 |
| 字段名称 | `to`, `value`, `data` | `target`, `value`, `hexData`, `isContractCall` |
| 数据编码 | 支持 ABI 自动编码 | 需要手动提供 hex 数据 |
| 配置方式 | `abi` + `params` 或直接 `data` | 直接 `hexData` |
| 复杂度 | 简单 | 复杂 |
| 适用场景 | 标准合约调用 | 自定义 hex 数据 |
| 配置难度 | 低 | 中等 |
| 可读性 | 高（使用 ABI） | 低（需要理解 hex） |

## 🛠️ 故障排除

### 常见错误

1. **配置文件不存在**
   ```
   ❌ 配置文件不存在: standard-batch-config.json
   ```
   **解决方案**: 确保配置文件存在于项目根目录

2. **配置格式错误**
   ```
   ❌ 配置文件 JSON 格式错误
   ```
   **解决方案**: 检查 JSON 格式是否正确

3. **缺少必需字段**
   ```
   ❌ 交易 1: 缺少 target 字段
   ```
   **解决方案**: 确保每个交易都包含 `target` 和 `value` 字段

4. **金额超限**
   ```
   ❌ 交易 1: 单笔交易金额超过限制
   ```
   **解决方案**: 调整交易金额或增加限制值

5. **地址白名单限制**
   ```
   ❌ 交易 1: 目标地址不在白名单中
   ```
   **解决方案**: 将目标地址添加到白名单或禁用白名单功能

### 调试技巧

1. **启用详细日志**: 检查脚本输出的详细信息
2. **验证网络连接**: 确保 RPC 端点正常工作
3. **检查余额**: 确保账户有足够的 ETH 支付 gas 费用
4. **测试小额交易**: 先用小额交易测试功能

## 📝 最佳实践

1. **先在测试网测试**: 在主网执行前先在测试网验证
2. **合理设置限制**: 根据实际需求设置金额限制
3. **使用白名单**: 对于生产环境，建议启用地址白名单
4. **备份配置**: 定期备份重要的配置文件
5. **监控执行**: 密切关注交易执行状态和 gas 消耗

## 🔗 相关链接

- [EIP-7702 标准](https://eips.ethereum.org/EIPS/eip-7702)
- [Hex 批量交易指南](HEX_BATCH_CONFIG_GUIDE.md)
- [合约验证指南](CONTRACT_VERIFICATION_GUIDE.md)
- [项目 README](README.md)

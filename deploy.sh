#!/bin/bash

# EIP-7702 智能账户合约部署脚本
echo -e "\033[1;34m✦  ˚  ✦  . ⋆ ˚   ✦  . ⋆ ˚   ✦ ˚ . ⋆   ˚ ✦  ˚  ✦  . ⋆   ˚ ✦  ˚\033[0m"
echo -e "\033[1;34m    ███████ ██ ██████        ███████ ███████  ██████  ██████  \033[0m"
echo -e "\033[1;34m    ██      ██ ██   ██            ██      ██ ██  ████      ██ \033[0m"
echo -e "\033[1;34m    █████   ██ ██████  █████     ██      ██  ██ ██ ██  █████  \033[0m"
echo -e "\033[1;34m    ██      ██ ██               ██      ██   ████  ██ ██      \033[0m"
echo -e "\033[1;34m    ███████ ██ ██               ██      ██    ██████  ███████ \033[0m"
echo -e "\033[1;34m                                                          \033[0m"
echo -e "\033[1;34m╔══════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;34m║\033[0m \033[1;33m          🚀 将 EOA 账户临时升级为智能合约账户 🚀           \033[0m \033[1;34m║\033[0m"
echo -e "\033[1;34m║                                                              ║\033[0m"
echo -e "\033[1;34m║  ✨ 支持标准批量交易                                         ║\033[0m"
echo -e "\033[1;34m║  🔥 支持 Hex 批量交易                                        ║\033[0m"
echo -e "\033[1;34m║  🌟 支持多链部署                                             ║\033[0m"
echo -e "\033[1;34m╚══════════════════════════════════════════════════════════════╝\033[0m"
echo -e "\033[1;34m✦  ˚  ✦  . ⋆ ˚   ✦  . ⋆ ˚   ✦ ˚ . ⋆   ˚ ✦  ˚  ✦  . ⋆   ˚ ✦  ˚ \033[0m"
echo -e "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

# 检查 .env 文件
echo -e "     \033[1;45m...🔍 检查环境配置...\033[0m"
if [ ! -f .env ]; then
    echo ""
    echo -e "\033[1;31m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;31m║                        ❌ 配置错误 ❌                        ║\033[0m"
    echo -e "\033[1;31m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo "📝 错误详情: .env 文件不存在"
    echo "💡 解决方案: 请先创建 .env 文件并配置必要的环境变量"
    echo ""
    echo "📋 示例 .env 文件内容:"
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│ RPC_URL=https://your-rpc-endpoint"
    echo "│ PRIVATE_KEY=your_private_key_here"
    echo "│ SCAN_URL=https://your-scan-url"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
    exit 1
fi
echo -e "\033[1;32m✅ 环境配置检查通过\033[0m"

# 加载环境变量
source .env

# 检查必要的环境变量
echo ""
echo -e "     \033[1;45m...🔄️ 验证环境变量...\033[0m"
if [ -z "$RPC_URL" ] || [ "$RPC_URL" = "your_rpc_url_here" ]; then
    echo ""
    echo -e "\033[1;31m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;31m║                        ❌ 配置错误 ❌                        ║\033[0m"
    echo -e "\033[1;31m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo "📝 错误详情: RPC_URL 未正确配置"
    echo "💡 解决方案: 请检查 .env 文件中的 RPC_URL 配置"
    echo ""
    exit 1
fi

if [ -z "$PRIVATE_KEY" ] || [ "$PRIVATE_KEY" = "your_private_key_here" ]; then
    echo ""
    echo -e "\033[1;31m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;31m║                        ❌ 配置错误 ❌                        ║\033[0m"
    echo -e "\033[1;31m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo "📝 错误详情: PRIVATE_KEY 未正确配置"
    echo "💡 解决方案: 请检查 .env 文件中的 PRIVATE_KEY 配置"
    echo ""
    exit 1
fi

# 自动识别网络并设置默认的区块浏览器 URL
# 初始化 CHAIN_ID_DEC 变量
CHAIN_ID_DEC=""

# 总是通过 RPC 调用获取 chain ID（用于验证）
echo -e "\033[1;36m⏳ 正在检测网络信息...\033[0m"
echo -e "\033[1;34m┌─────────────────────────────────────────────────────────────┐\033[0m"

# 通过 RPC 调用获取 chain ID
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
    "$RPC_URL" | grep -o '"result":"0x[0-9a-fA-F]*"' | cut -d'"' -f4)

if [ -n "$CHAIN_ID" ]; then
    # 将十六进制 chain ID 转换为十进制
    CHAIN_ID_DEC=$(printf "%d" "$CHAIN_ID")
    echo -e "\033[1;34m│ ✅ 检测到 Chain ID: $CHAIN_ID_DEC\033[0m"
    
    # 根据 chain ID 设置区块浏览器
    case $CHAIN_ID_DEC in
            1)
                SCAN_URL="https://etherscan.io"
                echo -e "\033[1;34m│ 🌐 检测到 Ethereum 主网\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            11155111)
                SCAN_URL="https://sepolia.etherscan.io"
                echo -e "\033[1;34m│ 🌐 检测到 Sepolia 测试网\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            137)
                SCAN_URL="https://polygonscan.com"
                echo -e "\033[1;34m│ 🌐 检测到 Polygon 网络\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            130)
                SCAN_URL="https://uniscan.xyz"
                echo -e "\033[1;34m│ 🌐 检测到 Unichain 网络\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            56)
                SCAN_URL="https://bscscan.com"
                echo -e "\033[1;34m│ 🌐 检测到 BSC 网络\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            97)
                SCAN_URL="https://testnet.bscscan.com"
                echo -e "\033[1;34m│ 🌐 检测到 BSC 测试网\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            42161)
                SCAN_URL="https://arbiscan.io"
                echo -e "\033[1;34m│ 🌐 检测到 Arbitrum One 网络\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            421614)
                SCAN_URL="https://sepolia.arbiscan.io"
                echo -e "\033[1;34m│ 🌐 检测到 Arbitrum Sepolia 测试网\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            10)
                SCAN_URL="https://optimistic.etherscan.io"
                echo -e "\033[1;34m│ 🌐 检测到 Optimism 网络\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            59144)
                SCAN_URL="https://lineascan.build"
                echo -e "\033[1;34m│ 🌐 检测到 Linea 网络\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            8453)
                SCAN_URL="https://basescan.org"
                echo -e "\033[1;34m│ 🌐 检测到 Base 网络\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            84532)
                SCAN_URL="https://sepolia.basescan.org"
                echo -e "\033[1;34m│ 🌐 检测到 Base Sepolia 测试网\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            43114)
                SCAN_URL="https://snowtrace.io"
                echo -e "\033[1;34m│ 🌐 检测到 Avalanche C-Chain 网络\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            80094)
                SCAN_URL="https://berascan.com"
                echo -e "\033[1;34m│ 🌐 检测到 Berachain 网络\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            250)
                SCAN_URL="https://ftmscan.com"
                echo -e "\033[1;34m│ 🌐 检测到 Fantom 网络\033[0m"
                echo -e "\033[1;34m│ 🔗 区块浏览器: $SCAN_URL\033[0m"
                ;;
            *)
                SCAN_URL="https://etherscan.io"
                echo -e "\033[1;34m│ ⚠️  未知 Chain ID: $CHAIN_ID_DEC\033[0m"
                echo -e "\033[1;34m│ 🔗 使用默认区块浏览器: $SCAN_URL\033[0m"
                ;;
        esac
    else
        SCAN_URL="https://etherscan.io"
        echo -e "\033[1;34m│ ❌ 无法通过 RPC 获取 Chain ID\033[0m"
        echo -e "\033[1;34m│ 🔗 使用默认区块浏览器: $SCAN_URL\033[0m"
    fi

echo -e "\033[1;34m└─────────────────────────────────────────────────────────────┘\033[0m"
echo ""
echo -e "\033[1;32m✅ 环境变量检查通过\033[0m"
echo -e "\033[1;34m┌─────────────────────────────────────────────────────────────┐\033[0m"
echo -e "\033[1;34m│\033[0m \033[1;36m📡 RPC URL:\033[0m ${RPC_URL:0:30}..."
echo -e "\033[1;34m│\033[0m \033[1;36m🔑 私钥:\033[0m ${PRIVATE_KEY:0:10}..."
echo -e "\033[1;34m│\033[0m \033[1;36m🔍 区块浏览器:\033[0m $SCAN_URL"
echo -e "\033[1;34m└─────────────────────────────────────────────────────────────┘\033[0m"

# 检查 Foundry 是否安装
echo ""
echo -e "     \033[1;45m...🔧 检查开发环境...\033[0m"
if ! command -v forge &> /dev/null; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                        ❌ 环境错误 ❌                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📝 错误详情: Foundry 未安装"
    echo "💡 解决方案: 请先安装 Foundry"
    echo "🔗 安装链接: https://book.getfoundry.sh/getting-started/installation"
    echo ""
    exit 1
fi
echo -e "\033[1;32m✅ 开发环境检查通过\033[0m"

# 检查合约文件是否存在
if [ ! -f "src/EIP7702SmartAccount.sol" ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                        ❌ 文件错误 ❌                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📝 错误详情: 合约文件不存在"
    echo "💡 解决方案: 请确保 src/EIP7702SmartAccount.sol 文件存在"
    echo ""
    exit 1
fi
echo -e "\033[1;32m✅ 合约文件检查通过\033[0m"

# 构建合约
echo ""
echo -e "     \033[1;45m...🔨 开始构建合约...\033[0m"
echo -e "\033[1;34m┌─────────────────────────────────────────────────────────────┐\033[0m"
forge build

if [ $? -ne 0 ]; then
    echo -e "\033[1;34m└─────────────────────────────────────────────────────────────┘\033[0m"
    echo ""
    echo -e "\033[1;31m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;31m║                        ❌ 构建失败 ❌                        ║\033[0m"
    echo -e "\033[1;31m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo -e "\033[1;33m📝 错误详情:\033[0m 合约构建失败"
    echo -e "\033[1;33m💡 解决方案:\033[0m 请检查合约代码是否有语法错误"
    echo ""
    exit 1
fi

echo -e "\033[1;34m└─────────────────────────────────────────────────────────────┘\033[0m"
echo ""
echo -e "\033[1;32m✅ 合约构建成功！\033[0m"

# 部署合约
echo ""
echo -e "     \033[1;45m...🚀 开始部署合约...\033[0m"

# 设置部署命令
DEPLOY_CMD="forge create src/EIP7702SmartAccount.sol:EIP7702SmartAccount --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast"

echo -e "\033[1;36m📋 执行部署命令:\033[0m"
echo -e "\033[1;34m┌─────────────────────────────────────────────────────────────┐\033[0m"
echo "$DEPLOY_CMD"
echo -e "\033[1;34m└─────────────────────────────────────────────────────────────┘\033[0m"
echo ""

# 执行部署
echo -e "\033[1;36m⏳ 正在部署合约，请稍候...\033[0m"
DEPLOY_OUTPUT=$(eval $DEPLOY_CMD 2>&1)
DEPLOY_EXIT_CODE=$?

# 检查部署结果
if [ $DEPLOY_EXIT_CODE -ne 0 ]; then
    echo ""
    echo -e "\033[1;31m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;31m║                        ❌ 部署失败 ❌                        ║\033[0m"
    echo -e "\033[1;31m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo -e "\033[1;33m📝 错误详情:\033[0m"
    echo -e "\033[1;34m┌─────────────────────────────────────────────────────────────┐\033[0m"
    echo "$DEPLOY_OUTPUT"
    echo -e "\033[1;34m└─────────────────────────────────────────────────────────────┘\033[0m"
    echo ""
    exit 1
fi

echo ""
echo -e "\033[1;32m✅ 部署命令执行成功！\033[0m"
echo -e "\033[1;36m📋 部署输出详情:\033[0m"
echo -e "\033[1;34m┌─────────────────────────────────────────────────────────────┐\033[0m"
echo "$DEPLOY_OUTPUT"
echo -e "\033[1;34m└─────────────────────────────────────────────────────────────┘\033[0m"

# 提取合约地址（支持多种输出格式）
CONTRACT_ADDRESS=""

# 尝试多种格式提取合约地址
PATTERNS=(
    "Deployed to: 0x[a-fA-F0-9]*"
    "Contract: 0x[a-fA-F0-9]*"
    "Deployed: 0x[a-fA-F0-9]*"
    "Address: 0x[a-fA-F0-9]*"
)

for pattern in "${PATTERNS[@]}"; do
    CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -o "$pattern" | head -1 | grep -o "0x[a-fA-F0-9]*")
    if [ -n "$CONTRACT_ADDRESS" ]; then
        break
    fi
done

# 如果还是没找到，尝试从日志中提取
if [ -z "$CONTRACT_ADDRESS" ]; then
    CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -o "0x[a-fA-F0-9]\{40\}" | head -1)
fi

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo ""
    echo -e "\033[1;31m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;31m║                        ❌ 提取失败 ❌                        ║\033[0m"
    echo -e "\033[1;31m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo -e "\033[1;33m📝 错误详情:\033[0m 无法提取合约地址"
    echo -e "\033[1;33m💡 解决方案:\033[0m 请手动从部署输出中查找合约地址"
    echo ""
    exit 1
fi

echo ""
echo -e "\033[1;32m╔══════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;32m║                        🎉 部署成功 🎉                        ║\033[0m"
echo -e "\033[1;32m╚══════════════════════════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[1;36m📋 实现合约地址:\033[0m \033[1;33m$CONTRACT_ADDRESS\033[0m"

# 保存部署信息
echo ""
echo -e "\033[1;36m📝 保存部署信息...\033[0m"
cat > deployment-info.txt << EOF
╔══════════════════════════════════════════════════════════════╗
║              EIP-7702 智能账户合约部署信息                    ║
╚══════════════════════════════════════════════════════════════╝

📅 部署时间: $(date)
🌐 RPC URL: ${RPC_URL:0:30}...
📋 实现合约地址: $CONTRACT_ADDRESS
🔑 私钥: ${PRIVATE_KEY:0:10}...

🚀 使用说明:
运行 Hex 批量交易: node scripts/eip7702-hex-batch.js


🔗 区块浏览器链接:
$SCAN_URL/address/$CONTRACT_ADDRESS

✨ 合约功能:
- EIP-7702 标准批量交易
- Hex 批量交易
- ERC20 批量转账
- 单笔交易执行

🌍 支持的 EVM 网络:
- 任何兼容 EVM 的网络
- 通过 RPC_URL 配置网络端点
EOF

echo -e "\033[1;32m✅ 部署信息已保存到 deployment-info.txt\033[0m"

# 更新 .env 文件中的 SMART_ACCOUNT_ADDRESS
echo ""
echo -e "\033[1;36m♻️ 更新环境配置...\033[0m"
if [ -f .env ]; then
    if grep -q "SMART_ACCOUNT_ADDRESS" .env; then
        # 如果已存在，则更新
        sed -i "s/SMART_ACCOUNT_ADDRESS=.*/SMART_ACCOUNT_ADDRESS=$CONTRACT_ADDRESS/" .env
        echo -e "\033[1;32m✅ 已更新 .env 文件中的 SMART_ACCOUNT_ADDRESS\033[0m"
    else
        # 如果不存在，则添加
        echo "" >> .env
        echo "# 智能账户合约地址（自动添加）" >> .env
        echo "SMART_ACCOUNT_ADDRESS=$CONTRACT_ADDRESS" >> .env
        echo -e "\033[1;32m✅ 已自动添加 SMART_ACCOUNT_ADDRESS 到 .env 文件\033[0m"
    fi
fi

echo ""
echo -e "\033[1;32m╔══════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;32m║                        🎉 部署完成 🎉                        ║\033[0m"
echo -e "\033[1;32m╚══════════════════════════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[1;36m📋 部署总结:\033[0m"
echo -e "\033[1;34m┌─────────────────────────────────────────────────────────────┐\033[0m"
echo -e "\033[1;34m│\033[0m \033[1;36m📋 实现合约地址:\033[0m \033[1;33m$CONTRACT_ADDRESS\033[0m"
echo -e "\033[1;34m│\033[0m \033[1;36m📄 部署信息:\033[0m deployment-info.txt"
echo -e "\033[1;34m│\033[0m \033[1;36m🔗 区块浏览器:\033[0m $SCAN_URL/address/$CONTRACT_ADDRESS"
echo -e "\033[1;34m└─────────────────────────────────────────────────────────────┘\033[0m"
echo ""
echo ""
echo -e "        🌿\033[1;45;7m如需验证合约（将合约开源），请参考以下指南\033[0m🌿"
echo -e "\033[1;34m┌─────────────────────────────────────────────────────────────┐\033[0m"
echo -e "\033[1;34m│\033[0m \033[1;35m📄 CONTRACT_VERIFICATION_GUIDE.md\033[0m"
echo -e "\033[1;34m└─────────────────────────────────────────────────────────────┘\033[0m"
echo ""

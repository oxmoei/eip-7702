// 加载环境变量
require('dotenv').config({ silent: true });

const { createWalletClient, createPublicClient, http, parseEther, encodeFunctionData, hashMessage, recoverPublicKey } = require('viem');
const { privateKeyToAccount } = require('viem/accounts');
const { sign } = require('viem/accounts');
const chalk = require('chalk'); // 用于美化输出

/**
 * EIP-7702 Hex 批量交易脚本
 * 支持自定义 hex 数据的批量交易执行
 */

// 配置
const CONFIG = {
    PRIVATE_KEY: process.env.PRIVATE_KEY,
    RPC_URL: process.env.RPC_URL,
    IMPLEMENTATION_ADDRESS: process.env.SMART_ACCOUNT_ADDRESS,
    NETWORK: process.env.NETWORK,
    ENABLE_HEX_BATCH: process.env.ENABLE_HEX_BATCH === 'true',
    GAS_LIMIT: process.env.GAS_LIMIT ? parseInt(process.env.GAS_LIMIT) : undefined,
    GAS_PRICE_STRATEGY: process.env.GAS_PRICE_STRATEGY || 'auto',
    TRANSACTION_TIMEOUT: process.env.TRANSACTION_TIMEOUT ? parseInt(process.env.TRANSACTION_TIMEOUT) : 300,
    MAX_RETRIES: process.env.MAX_RETRIES ? parseInt(process.env.MAX_RETRIES) : 3,
    MAX_SINGLE_TRANSACTION_VALUE: process.env.MAX_SINGLE_TRANSACTION_VALUE ? BigInt(process.env.MAX_SINGLE_TRANSACTION_VALUE) : parseEther('1'),
    MAX_BATCH_TOTAL_VALUE: process.env.MAX_BATCH_TOTAL_VALUE ? BigInt(process.env.MAX_BATCH_TOTAL_VALUE) : parseEther('5'),
    ENABLE_ADDRESS_WHITELIST: process.env.ENABLE_ADDRESS_WHITELIST === 'true',
    ALLOWED_TARGETS: process.env.ALLOWED_TARGETS ? process.env.ALLOWED_TARGETS.split(',') : [],
    CONFIG_FILE: process.env.HEX_BATCH_CONFIG_FILE || 'call_data/hex-batch-config.json',
    LOG_LEVEL: process.env.LOG_LEVEL || 'info',
};

class EIP7702HexBatchDemo {
    constructor(config) {
        this.config = config;
        this.account = privateKeyToAccount(config.PRIVATE_KEY);
        
        // 创建客户端（不指定特定网络，让 viem 自动处理）
        this.walletClient = createWalletClient({
            account: this.account,
            transport: http(config.RPC_URL),
        });
        
        this.publicClient = createPublicClient({
            transport: http(config.RPC_URL),
        });
    }

    async demonstrateHexBatch() {
                                // 打印精美的标题横幅
        console.log(chalk.cyan.bold(`
✦  ˚  ✦  . ⋆ ˚   ✦  . ⋆ ˚   ✦  . ⋆ ˚   ✦ ˚ . ⋆   ˚ ✦  ˚  ✦  . ⋆   ˚ ✦  ˚       
          ███████╗██╗██████╗    ███████╗███████╗ ██████╗ ██████╗ 
          ██╔════╝██║██╔══██╗   ╚════██║╚════██║██╔═████╗╚════██╗
          █████╗  ██║██████╔╝█████╗ ██╔╝    ██╔╝██║██╔██║ █████╔╝
          ██╔══╝  ██║██╔═══╝ ╚════╝██╔╝    ██╔╝ ████╔╝██║██╔═══╝ 
          ███████╗██║██║           ██║     ██║  ╚██████╔╝███████╗
          ╚══════╝╚═╝╚═╝           ╚═╝     ╚═╝   ╚═════╝ ╚══════╝
                                                       
          ╔══════════════════════════════════════════════════════╗
          ║            🎯 EIP-7702 Hex 批量交易                  ║
          ║       Advanced Smart Account Operations              ║
          ╚══════════════════════════════════════════════════════╝
✦  ˚  ✦  . ⋆ ˚   ✦  . ⋆ ˚   ✦  . ⋆ ˚   ✦ ˚ . ⋆   ˚ ✦  ˚  ✦  . ⋆   ˚ ✦  ˚
`));
        
        console.log(chalk.cyan.bold('📋 系统配置信息:'));
        console.log(chalk.gray('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
        console.log(chalk.blue(`👤 EOA 地址:     ${chalk.yellowBright(this.account.address)}`));
        console.log(chalk.blue(`📋 实现合约地址: ${chalk.yellowBright(this.config.IMPLEMENTATION_ADDRESS)}`));
        console.log(chalk.blue(`🔗 RPC URL:      ${chalk.white(this.config.RPC_URL)}`));
        if (this.config.SCAN_URL) {
            console.log(chalk.blue(`🔍 区块浏览器:   ${chalk.white(this.config.SCAN_URL)}`));
        }
        console.log(chalk.blue(`⚙️ Gas 策略:     ${chalk.white(this.config.GAS_PRICE_STRATEGY)}`));
        console.log(chalk.blue(`📝 日志级别:     ${chalk.white(this.config.LOG_LEVEL)}`));
        console.log(chalk.gray('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
        console.log('');

        // 验证配置
        this.validateConfig();
        
        // 获取网络信息
        await this.getNetworkInfo();

        // 步骤 1: 检查 EOA 初始状态
        console.log(chalk.magenta.bold('🔍 步骤 1: 检查 EOA 初始状态'));
        console.log(chalk.gray('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
        await this.checkAccountStatus(this.account.address, 'EOA');
        console.log('');

        // 步骤 2: 生成 EIP-7702 授权
        console.log(chalk.magenta.bold('🔐 步骤 2: 生成 EIP-7702 授权签名'));
        console.log(chalk.gray('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
        const authorization = await this.generateAuthorization();
        console.log(chalk.green.bold('✅ 授权生成成功'));
        console.log('');

        // 步骤 3: 准备 hex 批量交易
        console.log(chalk.magenta.bold('📌 步骤 3: 准备 hex 批量交易'));
        console.log(chalk.gray('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
        const hexTransactions = await this.prepareHexBatchTransactions();
        console.log('');

        // 步骤 4: 执行 hex 批量交易
        console.log(chalk.magenta.bold('🚀 步骤 4: 执行 hex 批量交易'));
        console.log(chalk.gray('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
        const txHash = await this.executeHexBatchTransaction(authorization, hexTransactions);
        console.log(chalk.green.bold('✅ Hex 批量交易发送成功'));
        console.log(chalk.blue(`🆔 交易哈希: ${chalk.yellowBright(txHash)}`));
        console.log('');

        // 步骤 5: 等待交易确认
        console.log(chalk.magenta.bold('⏳ 步骤 5: 等待交易确认'));
        console.log(chalk.gray('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
        const receipt = await this.waitForTransaction(txHash);
        console.log(chalk.green.bold('✅ 交易确认成功'));
        console.log(chalk.blue(`💰 Gas 使用: ${chalk.white(receipt.gasUsed.toString())}`));
        console.log('');

        // 步骤 6: 检查 EOA 最终状态
        console.log(chalk.magenta.bold('📋 步骤 6: 检查 EOA 最终状态'));
        console.log(chalk.gray('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
        await this.checkAccountStatus(this.account.address, 'EOA (升级后)');
        console.log('');

        // 完成总结
        console.log(chalk.green.bold(`
╔══════════════════════════════════════════════════════════════════════════════╗
║                           🎉 Hex 批量交易完成！                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
`));
    }

    validateConfig() {
        if (!this.config.PRIVATE_KEY) {
            throw new Error(chalk.red.bold('❌ 请设置有效的 PRIVATE_KEY 环境变量'));
        }
        
        if (!this.config.RPC_URL) {
            throw new Error(chalk.red.bold('❌ 请设置有效的 RPC_URL 环境变量'));
        }
        
        if (!this.config.IMPLEMENTATION_ADDRESS) {
            throw new Error(chalk.red.bold('❌ 请设置有效的 SMART_ACCOUNT_ADDRESS 环境变量'));
        }

        if (!this.config.ENABLE_HEX_BATCH) {
            throw new Error(chalk.red.bold('❌ Hex 批量交易功能未启用，请设置 ENABLE_HEX_BATCH=true'));
        }
    }

    async getNetworkInfo() {
        try {
            const chainId = await this.publicClient.getChainId();
            console.log(chalk.cyan.bold('🌐 网络信息:'));
            console.log(chalk.gray('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
            console.log(chalk.blue(`  链 ID:        ${chalk.white(chainId)}`));
            
            // 根据链 ID 识别网络名称
            const networkName = this.getNetworkName(chainId);
            console.log(chalk.blue(`  网络:         ${chalk.yellowBright(networkName)}`));
            
            // 获取区块浏览器 URL
            const blockExplorerUrl = this.getBlockExplorerUrl(chainId);
            console.log(chalk.blue(`  区块浏览器:   ${chalk.white(blockExplorerUrl)}`));
            console.log(chalk.gray('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
            console.log('');
            
            return { chainId, networkName, blockExplorerUrl };
        } catch (error) {
            console.log(chalk.yellow('⚠️  无法获取网络信息，继续执行...'));
            return { chainId: null, networkName: 'Unknown', blockExplorerUrl: 'https://etherscan.io' };
        }
    }

    getNetworkName(chainId) {
        const networks = {
            1: 'Ethereum Mainnet',
            11155111: 'Sepolia Testnet',
            137: 'Polygon',
            56: 'BSC',
            97: 'BSC Testnet',
            10: 'Optimism',
            8453: 'Base',
            84532: 'Base Sepolia',
            43114: 'Avalanche C-Chain',
            250: 'Fantom'
        };
        
        return networks[chainId] || `Chain ID ${chainId}`;
    }

    getBlockExplorerUrl(chainId) {
        const explorers = {
            1: 'https://etherscan.io',
            11155111: 'https://sepolia.etherscan.io',
            137: 'https://polygonscan.com',
            56: 'https://bscscan.com',
            97: 'https://testnet.bscscan.com',
            42161: 'https://arbiscan.io',
            59144: 'https://lineascan.build/',
            10: 'https://optimistic.etherscan.io',
            196: 'https://www.oklink.com/zh-hans/x-layer',
            8453: 'https://basescan.org',
            84532: 'https://sepolia.basescan.org',
            43114: 'https://snowtrace.io',
            146: 'https://sonicscan.org/',
            80094: 'https://berascan.com/',
            130: 'https://uniscan.xyz/',
            250: 'https://ftmscan.com'
        };
        
        return explorers[chainId] || 'https://etherscan.io';
    }

    async checkAccountStatus(address, label) {
        console.log(chalk.green(`📊 检查 ${label} 状态:`));
        console.log(chalk.gray('  -----------------------------------------------------------'));
        console.log(chalk.blue(`  地址:   ${chalk.white(address)}`));

        try {
            const code = await this.publicClient.getCode({ address });
            if (code && code !== '0x') {
                console.log(chalk.blue(`    📦 状态:       ${chalk.white('智能合约 (有代码)')}`));
            } else {
                console.log(chalk.blue(`    👤 状态:       ${chalk.white('EOA (无代码)')}`));
            }
        } catch (error) {
            console.log(chalk.red(`  ❌ 无法检查合约代码: ${error.message}`));
        }
        
        try {
            const balance = await this.publicClient.getBalance({ address });
            const ethBalance = Number(balance) / Math.pow(10, 18);
            console.log(chalk.blue(`    💴 余额:       ${chalk.yellowBright(ethBalance.toFixed(6))} ETH`));
            console.log(chalk.gray('  -----------------------------------------------------------'));
        } catch (error) {
            console.log(chalk.red(`  ❌ 无法获取余额: ${error.message}`));
        }
    }

    async generateAuthorization() {
        const chainId = await this.publicClient.getChainId();
        const nonce = await this.publicClient.getTransactionCount({ address: this.account.address });
        
        // 按照合约中的方式生成消息哈希
        const { keccak256, encodePacked } = require('viem');
        const messageHash = keccak256(encodePacked(
            ['uint256', 'uint256', 'address'],
            [chainId, nonce, this.config.IMPLEMENTATION_ADDRESS]
        ));
        
        // 使用以太坊签名前缀 (MessageHashUtils.toEthSignedMessageHash)
        const ethSignedMessageHash = keccak256(encodePacked(
            ['string', 'bytes32'],
            ['\x19Ethereum Signed Message:\n32', messageHash]
        ));
        
        const signature = await sign({ hash: ethSignedMessageHash, privateKey: this.config.PRIVATE_KEY });
        const yParity = Number(signature.yParity);
        
        return {
            chainId: chainId,
            nonce: nonce,
            implementation: this.config.IMPLEMENTATION_ADDRESS,
            yParity: yParity,
            r: signature.r,
            s: signature.s
        };
    }

    async prepareHexBatchTransactions() {
        // 检查是否启用了 hex 批量交易
        if (!this.config.ENABLE_HEX_BATCH) {
            throw new Error(chalk.red.bold('❌ 未启用 hex 批量交易功能。请在 .env 中设置 ENABLE_HEX_BATCH=true'));
        }

        let hexTransactions = [];
        const fs = require('fs');
        const path = require('path');

        // 尝试从 JSON 文件加载配置
        const configFilePath = path.join(__dirname, '..', this.config.CONFIG_FILE);
        
        try {
            if (!fs.existsSync(configFilePath)) {
                throw new Error(chalk.red.bold(`❌ 配置文件不存在: ${configFilePath}`));
            }

            const configData = fs.readFileSync(configFilePath, 'utf8');
            const config = JSON.parse(configData);
            
            if (!config.transactions || !Array.isArray(config.transactions) || config.transactions.length === 0) {
                throw new Error(chalk.red.bold('配置文件中必须包含非空的 transactions 数组'));
            }

            // 更新配置中的设置（如果存在）
            if (config.settings) {
                if (config.settings.maxSingleTransactionValue) {
                    this.config.MAX_SINGLE_TRANSACTION_VALUE = BigInt(config.settings.maxSingleTransactionValue);
                }
                if (config.settings.maxBatchTotalValue) {
                    this.config.MAX_BATCH_TOTAL_VALUE = BigInt(config.settings.maxBatchTotalValue);
                }
                if (config.settings.enableAddressWhitelist !== undefined) {
                    this.config.ENABLE_ADDRESS_WHITELIST = config.settings.enableAddressWhitelist;
                }
                if (config.settings.allowedTargets) {
                    this.config.ALLOWED_TARGETS = config.settings.allowedTargets;
                }
            }

            hexTransactions = config.transactions.map((tx, index) => {
                // 验证必需字段
                if (!tx.target) {
                    throw new Error(chalk.red.bold(`交易 ${index + 1}: 缺少 target 字段`));
                }
                if (tx.value === undefined || tx.value === null) {
                    throw new Error(chalk.red.bold(`交易 ${index + 1}: 缺少 value 字段`));
                }

                return {
                    target: tx.target,
                    value: BigInt(tx.value),
                    hexData: tx.hexData || '0x',
                    isContractCall: tx.isContractCall || false,
                    description: tx.description || `交易 ${index + 1}`
                };
            });

            console.log(chalk.green(`📁 从配置文件加载: ${this.config.CONFIG_FILE}`));
            const maxSingleETH = Number(this.config.MAX_SINGLE_TRANSACTION_VALUE) / Math.pow(10, 18);
            const maxBatchETH = Number(this.config.MAX_BATCH_TOTAL_VALUE) / Math.pow(10, 18);
            console.log(chalk.gray(` ┗━━ 配置设置: 最大单笔交易 ${chalk.white(maxSingleETH.toFixed(6))} ETH, 最大批量交易 ${chalk.white(maxBatchETH.toFixed(6))} ETH`));
            if (this.config.ENABLE_ADDRESS_WHITELIST) {
                console.log(chalk.blue(`🔒 地址白名单: ${chalk.white(this.config.ALLOWED_TARGETS.length)} 个地址`));
            }
            console.log('');

        } catch (error) {
            if (error instanceof SyntaxError) {
                throw new Error(chalk.red.bold(`❌ 配置文件 JSON 格式错误: ${error.message}`));
            } else {
                throw new Error(chalk.red.bold(`❌ 配置文件错误: ${error.message}`));
            }
        }

        // 验证交易
        this.validateHexTransactions(hexTransactions);

        // 打印交易详情
        console.log(chalk.green.bold('\n📋 Hex 批量交易详情:'));
        console.log(chalk.gray('  ---------------------------------------------------------'));
        hexTransactions.forEach((tx, index) => {
            console.log(chalk.gray(`  ${index + 1}. ${tx.description}`));
            console.log(chalk.blue(`     目标地址:     ${chalk.white(tx.target)}`));
            console.log(chalk.blue(`     ETH 数量:     ${chalk.white(tx.value)} wei (${tx.value / 10n**18n} ETH)`));
            console.log(chalk.blue(`     Hex 数据:     ${chalk.white(tx.hexData)}`));
            console.log(chalk.blue(`     合约调用:     ${chalk.white(tx.isContractCall ? '是' : '否')}`));
            console.log('');
        });
        console.log(chalk.gray('  ---------------------------------------------------------'));
        return hexTransactions;
    }

    validateHexTransactions(transactions) {
        let totalValue = 0n;

        for (let i = 0; i < transactions.length; i++) {
            const tx = transactions[i];
            
            // 验证地址格式
            if (!tx.target || tx.target.length !== 42 || !tx.target.startsWith('0x')) {
                throw new Error(chalk.red.bold(`交易 ${i + 1}: 无效的目标地址 ${tx.target}`));
            }

            // 验证金额限制
            if (tx.value > this.config.MAX_SINGLE_TRANSACTION_VALUE) {
                throw new Error(chalk.red.bold(`交易 ${i + 1}: 单笔交易金额超过限制 ${this.config.MAX_SINGLE_TRANSACTION_VALUE} wei`));
            }

            // 验证地址白名单
            if (this.config.ENABLE_ADDRESS_WHITELIST && !this.config.ALLOWED_TARGETS.includes(tx.target)) {
                throw new Error(chalk.red.bold(`交易 ${i + 1}: 目标地址 ${tx.target} 不在白名单中`));
            }

            totalValue += tx.value;
        }

        // 验证总金额限制
        if (totalValue > this.config.MAX_BATCH_TOTAL_VALUE) {
            throw new Error(chalk.red.bold(`批量交易总金额超过限制 ${this.config.MAX_BATCH_TOTAL_VALUE} wei`));
        }

        console.log(chalk.green(`✅ 验证通过: ${chalk.yellowBright(transactions.length)} ${chalk.green('笔交易，总金额')} ${chalk.yellowBright(totalValue)} wei (${chalk.yellowBright(totalValue / 10n**18n)} ETH)`));
    }

    async executeHexBatchTransaction(authorization, hexTransactions) {
        // 编码 hex 批量调用数据
        const data = encodeFunctionData({
            abi: [{
                "inputs": [
                    {
                        "components": [
                            {"name": "chainId", "type": "uint256"},
                            {"name": "nonce", "type": "uint256"},
                            {"name": "implementation", "type": "address"},
                            {"name": "yParity", "type": "uint8"},
                            {"name": "r", "type": "bytes32"},
                            {"name": "s", "type": "bytes32"}
                        ],
                        "name": "authorization",
                        "type": "tuple"
                    },
                    {
                        "components": [
                            {"name": "target", "type": "address"},
                            {"name": "value", "type": "uint256"},
                            {"name": "hexData", "type": "bytes"},
                            {"name": "isContractCall", "type": "bool"}
                        ],
                        "name": "transactions",
                        "type": "tuple[]"
                    }
                ],
                "name": "executeHexBatchWithAuthorization",
                "outputs": [],
                "stateMutability": "payable",
                "type": "function"
            }],
            functionName: 'executeHexBatchWithAuthorization',
            args: [authorization, hexTransactions]
        });

        // 计算总价值
        const totalValue = hexTransactions.reduce((sum, tx) => sum + tx.value, 0n);

        // 准备交易参数
        const transactionRequest = {
            data: data,
            to: this.config.IMPLEMENTATION_ADDRESS,
            value: totalValue
        };

        // 添加 gas 配置
        if (this.config.GAS_LIMIT) {
            transactionRequest.gas = BigInt(this.config.GAS_LIMIT);
        }

        // 发送交易
        const hash = await this.walletClient.sendTransaction(transactionRequest);
        return hash;
    }

    async waitForTransaction(hash) {
        return await this.publicClient.waitForTransactionReceipt({
            hash: hash,
            timeout: this.config.TRANSACTION_TIMEOUT * 1000
        });
    }
}

async function main() {
    const demo = new EIP7702HexBatchDemo(CONFIG);
    
    try {
        await demo.demonstrateHexBatch();
    } catch (error) {
        console.log(chalk.red.bold(`
╔══════════════════════════════════════════════════════════════════════════════╗
║                            💥 脚本执行失败                                   ║
║                              Script Execution Failed                        ║
╚══════════════════════════════════════════════════════════════════════════════╝
`));
        console.log(chalk.red.bold(`❌ 错误详情: ${error.message}`));
        console.log(chalk.gray('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
        console.log(chalk.yellow('💡 请检查以下可能的问题:'));
        console.log(chalk.yellow('   1. 环境变量配置是否正确'));
        console.log(chalk.yellow('   2. 网络连接是否正常'));
        console.log(chalk.yellow('   3. 私钥和地址是否有效'));
        console.log(chalk.yellow('   4. 配置文件是否存在且格式正确'));
        console.log(chalk.gray('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'));
        process.exit(1);
    }
}

module.exports = { EIP7702HexBatchDemo, CONFIG };

if (require.main === module) {
    main();
}

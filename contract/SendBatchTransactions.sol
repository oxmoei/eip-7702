// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title SendBatchTransactions
 * @notice Self-contained EIP-7702 smart account with batch functionality
 * @dev This contract handles both EIP-7702 upgrade and batch execution
 */
contract SendBatchTransactions {
    using ECDSA for bytes32;

    /// @notice Authorization structure for EIP-7702
    struct Authorization {
        uint256 chainId;
        uint256 nonce;
        address implementation;
        uint8 yParity;
        bytes32 r;
        bytes32 s;
    }

    /// @notice Call structure for batch execution
    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    /// @notice Hex batch transaction structure
    struct HexBatchTransaction {
        address target;
        uint256 value;
        bytes hexData;
        bool isContractCall;
    }

    /// @notice Mapping to track used nonces for replay protection
    mapping(address => mapping(uint256 => bool)) public usedNonces;

    /// @notice Event emitted when account is upgraded
    event AccountUpgraded(address indexed account, address indexed implementation, uint256 nonce);
    /// @notice Event emitted when account is reverted
    event AccountReverted(address indexed account);
    /// @notice Event emitted for batch execution
    event BatchExecuted(uint256 indexed nonce, Call[] calls);
    /// @notice Event emitted for hex batch execution
    event HexBatchExecuted(uint256 indexed nonce, HexBatchTransaction[] transactions);
    /// @notice Event emitted for individual call execution
    event CallExecuted(address indexed sender, address indexed to, uint256 value, bytes data);
    /// @notice Event emitted for hex transaction execution
    event HexTransactionExecuted(address indexed sender, address indexed target, uint256 value, bytes hexData, bool isContractCall);

    /**
     * @notice Validates EIP-7702 authorization
     * @param authorization The authorization data
     * @return isValid Whether the authorization is valid
     */
    function validateAuthorization(Authorization calldata authorization) public view returns (bool isValid) {
        // Check if nonce has been used
        if (usedNonces[msg.sender][authorization.nonce]) {
            return false;
        }

        // Check chain ID
        if (authorization.chainId != block.chainid) {
            return false;
        }

        // Reconstruct the message hash
        bytes32 messageHash = keccak256(abi.encodePacked(
            authorization.chainId,
            authorization.nonce,
            authorization.implementation
        ));

        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);

        // Recover the signer
        address signer = ecrecover(
            ethSignedMessageHash,
            authorization.yParity + 27,
            authorization.r,
            authorization.s
        );

        // Verify the signer is the account owner
        return signer == msg.sender;
    }

    /**
     * @notice Executes hex batch transactions with EIP-7702 authorization
     * @param authorization The authorization data
     * @param transactions Array of hex transactions to execute
     */
    function executeHexBatchWithAuthorization(
        Authorization calldata authorization,
        HexBatchTransaction[] calldata transactions
    ) external payable {
        require(validateAuthorization(authorization), "Invalid authorization");
        require(!usedNonces[msg.sender][authorization.nonce], "Nonce already used");

        // Mark nonce as used
        usedNonces[msg.sender][authorization.nonce] = true;

        // Emit upgrade event
        emit AccountUpgraded(msg.sender, authorization.implementation, authorization.nonce);

        // Execute hex batch transactions
        uint256 currentNonce = authorization.nonce;
        
        for (uint256 i = 0; i < transactions.length; i++) {
            _executeHexTransaction(transactions[i]);
        }

        // Emit hex batch execution event
        emit HexBatchExecuted(currentNonce, transactions);

        // Emit revert event (account returns to EOA state)
        emit AccountReverted(msg.sender);
    }

    /**
     * @notice Executes a single hex transaction with EIP-7702 authorization
     * @param authorization The authorization data
     * @param target The target address
     * @param value The ETH value to send
     * @param hexData The hex data to send
     * @param isContractCall Whether this is a contract call or simple transfer
     */
    function executeHexWithAuthorization(
        Authorization calldata authorization,
        address target,
        uint256 value,
        bytes calldata hexData,
        bool isContractCall
    ) external payable {
        require(validateAuthorization(authorization), "Invalid authorization");
        require(!usedNonces[msg.sender][authorization.nonce], "Nonce already used");

        // Mark nonce as used
        usedNonces[msg.sender][authorization.nonce] = true;

        // Emit upgrade event
        emit AccountUpgraded(msg.sender, authorization.implementation, authorization.nonce);

        // Execute the hex transaction
        HexBatchTransaction memory transaction = HexBatchTransaction(target, value, hexData, isContractCall);
        _executeHexTransaction(transaction);

        // Emit revert event (account returns to EOA state)
        emit AccountReverted(msg.sender);
    }

    /**
     * @dev Internal function to execute a single hex transaction
     * @param transaction The hex transaction to execute
     */
    function _executeHexTransaction(HexBatchTransaction memory transaction) internal {
        if (transaction.isContractCall) {
            // Contract call with hex data
            (bool success, bytes memory result) = transaction.target.call{value: transaction.value}(transaction.hexData);
            
            if (!success) {
                if (result.length > 0) {
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert("Hex transaction reverted");
                }
            }
        } else {
            // Simple ETH transfer (hexData should be empty or ignored)
            if (transaction.hexData.length > 0) {
                // If hexData is provided but not a contract call, we still execute it
                (bool success, bytes memory result) = transaction.target.call{value: transaction.value}(transaction.hexData);
                
                if (!success) {
                    if (result.length > 0) {
                        assembly {
                            let returndata_size := mload(result)
                            revert(add(32, result), returndata_size)
                        }
                    } else {
                        revert("Hex transaction reverted");
                    }
                }
            } else {
                // Pure ETH transfer
                (bool success, ) = transaction.target.call{value: transaction.value}("");
                require(success, "ETH transfer failed");
            }
        }
        
        emit HexTransactionExecuted(msg.sender, transaction.target, transaction.value, transaction.hexData, transaction.isContractCall);
    }

    /**
     * @notice Executes batch calls with EIP-7702 authorization
     * @param authorization The authorization data
     * @param calls Array of calls to execute
     */
    function executeBatchWithAuthorization(
        Authorization calldata authorization,
        Call[] calldata calls
    ) external payable {
        require(validateAuthorization(authorization), "Invalid authorization");
        require(!usedNonces[msg.sender][authorization.nonce], "Nonce already used");

        // Mark nonce as used
        usedNonces[msg.sender][authorization.nonce] = true;

        // Emit upgrade event
        emit AccountUpgraded(msg.sender, authorization.implementation, authorization.nonce);

        // Execute batch calls
        uint256 currentNonce = authorization.nonce;
        
        for (uint256 i = 0; i < calls.length; i++) {
            _executeCall(calls[i]);
        }

        // Emit batch execution event
        emit BatchExecuted(currentNonce, calls);

        // Emit revert event (account returns to EOA state)
        emit AccountReverted(msg.sender);
    }

    /**
     * @notice Executes a single call with EIP-7702 authorization
     * @param authorization The authorization data
     * @param target The target address
     * @param value The ETH value to send
     * @param data The call data
     */
    function executeWithAuthorization(
        Authorization calldata authorization,
        address target,
        uint256 value,
        bytes calldata data
    ) external payable {
        require(validateAuthorization(authorization), "Invalid authorization");
        require(!usedNonces[msg.sender][authorization.nonce], "Nonce already used");

        // Mark nonce as used
        usedNonces[msg.sender][authorization.nonce] = true;

        // Emit upgrade event
        emit AccountUpgraded(msg.sender, authorization.implementation, authorization.nonce);

        // Execute the call
        Call memory call = Call(target, value, data);
        _executeCall(call);

        // Emit revert event (account returns to EOA state)
        emit AccountReverted(msg.sender);
    }

    /**
     * @dev Internal function to execute a single call
     * @param call The call to execute
     */
    function _executeCall(Call memory call) internal {
        (bool success, bytes memory result) = call.to.call{value: call.value}(call.data);
        
        if (!success) {
            if (result.length > 0) {
                assembly {
                    let returndata_size := mload(result)
                    revert(add(32, result), returndata_size)
                }
            } else {
                revert("Call reverted");
            }
        }
        
        emit CallExecuted(msg.sender, call.to, call.value, call.data);
    }

    /**
     * @notice Direct hex batch execution (for when account is already upgraded)
     * @param transactions Array of hex transactions to execute
     */
    function executeHexBatch(HexBatchTransaction[] calldata transactions) external payable {
        require(msg.sender == address(this), "Only self can call");
        
        for (uint256 i = 0; i < transactions.length; i++) {
            _executeHexTransaction(transactions[i]);
        }
        
        emit HexBatchExecuted(0, transactions);
    }

    /**
     * @notice Direct hex transaction execution (for when account is already upgraded)
     * @param target The target address
     * @param value The ETH value to send
     * @param hexData The hex data to send
     * @param isContractCall Whether this is a contract call or simple transfer
     */
    function executeHex(address target, uint256 value, bytes calldata hexData, bool isContractCall) external payable {
        require(msg.sender == address(this), "Only self can call");
        
        HexBatchTransaction memory transaction = HexBatchTransaction(target, value, hexData, isContractCall);
        _executeHexTransaction(transaction);
    }

    /**
     * @notice Direct batch execution (for when account is already upgraded)
     * @param calls Array of calls to execute
     */
    function executeBatch(Call[] calldata calls) external payable {
        require(msg.sender == address(this), "Only self can call");
        
        for (uint256 i = 0; i < calls.length; i++) {
            _executeCall(calls[i]);
        }
        
        emit BatchExecuted(0, calls);
    }

    /**
     * @notice Direct single call execution (for when account is already upgraded)
     * @param target The target address
     * @param value The ETH value to send
     * @param data The call data
     */
    function execute(address target, uint256 value, bytes calldata data) external payable {
        require(msg.sender == address(this), "Only self can call");
        
        Call memory call = Call(target, value, data);
        _executeCall(call);
    }

    /// @notice Allow the contract to receive ETH
    fallback() external payable {}
    receive() external payable {}
}

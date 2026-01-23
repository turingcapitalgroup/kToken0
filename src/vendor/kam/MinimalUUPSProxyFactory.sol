// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { OptimizedLibClone } from "../solady/utils/OptimizedLibClone.sol";

import { IMinimalUUPSProxyFactory } from "../../interfaces/IMinimalUUPSProxyFactory.sol";

/// @title MinimalUUPSProxyFactory
/// @notice Factory for deploying minimal ERC1967I proxies with NO admin authority.
/// @dev Uses Solady's audited LibClone.deployERC1967I which deploys ERC-7760 minimal proxies.
///      The "I" suffix means "immutable admin" - there is NO admin, NO factory backdoor.
///      All upgrade authority is delegated to the implementation's UUPS _authorizeUpgrade().
contract MinimalUUPSProxyFactory is IMinimalUUPSProxyFactory {
    /* //////////////////////////////////////////////////////////////
                         DEPLOY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMinimalUUPSProxyFactory
    function deploy(address _implementation) external returns (address _proxy) {
        _proxy = OptimizedLibClone.deployERC1967I(_implementation);
        emit ProxyDeployed(_proxy, _implementation);
    }

    /// @inheritdoc IMinimalUUPSProxyFactory
    function deployAndCall(address _implementation, bytes calldata _data) external payable returns (address _proxy) {
        _proxy = OptimizedLibClone.deployERC1967I(_implementation);
        /// @solidity memory-safe-assembly
        assembly {
            let n := _data.length
            let m := mload(0x40) // Cache free memory pointer.
            calldatacopy(m, _data.offset, n)
            if iszero(call(gas(), _proxy, callvalue(), m, n, 0x00, 0x00)) {
                // Bubble up the revert reason from initialization.
                returndatacopy(m, 0x00, returndatasize())
                revert(m, returndatasize())
            }
        }
        emit ProxyDeployed(_proxy, _implementation);
    }

    /// @inheritdoc IMinimalUUPSProxyFactory
    function deployDeterministic(address _implementation, bytes32 _salt) external returns (address _proxy) {
        _proxy = OptimizedLibClone.deployDeterministicERC1967I(_implementation, _salt);
        emit ProxyDeployed(_proxy, _implementation);
    }

    /// @inheritdoc IMinimalUUPSProxyFactory
    function deployDeterministicAndCall(
        address _implementation,
        bytes32 _salt,
        bytes calldata _data
    )
        external
        payable
        returns (address _proxy)
    {
        _proxy = OptimizedLibClone.deployDeterministicERC1967I(_implementation, _salt);
        /// @solidity memory-safe-assembly
        assembly {
            let n := _data.length
            let m := mload(0x40) // Cache free memory pointer.
            calldatacopy(m, _data.offset, n)
            if iszero(call(gas(), _proxy, callvalue(), m, n, 0x00, 0x00)) {
                // Bubble up the revert reason from initialization.
                returndatacopy(m, 0x00, returndatasize())
                revert(m, returndatasize())
            }
        }
        emit ProxyDeployed(_proxy, _implementation);
    }

    /* //////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMinimalUUPSProxyFactory
    function predictDeterministicAddress(address _implementation, bytes32 _salt) external view returns (address) {
        return OptimizedLibClone.predictDeterministicAddressERC1967I(_implementation, _salt, address(this));
    }

    /// @inheritdoc IMinimalUUPSProxyFactory
    function initCodeHash(address _implementation) external pure returns (bytes32) {
        return OptimizedLibClone.initCodeHashERC1967I(_implementation);
    }
}

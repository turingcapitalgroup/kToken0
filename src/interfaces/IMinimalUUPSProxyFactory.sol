// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/// @title IMinimalUUPSProxyFactory
/// @notice Interface for deploying minimal ERC1967I proxies with NO admin authority.
/// @dev All upgrade authority is delegated to the implementation's UUPS _authorizeUpgrade().
interface IMinimalUUPSProxyFactory {
    /* //////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new proxy is deployed
    /// @param proxy The deployed proxy address
    /// @param implementation The implementation address the proxy points to
    event ProxyDeployed(address indexed proxy, address indexed implementation);

    /* //////////////////////////////////////////////////////////////
                              FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys a minimal ERC1967I proxy for the given implementation.
    /// @param _implementation The implementation contract address
    /// @return _proxy The deployed proxy address
    function deploy(address _implementation) external returns (address _proxy);

    /// @notice Deploys a minimal ERC1967I proxy and calls it with initialization data.
    /// @param _implementation The implementation contract address
    /// @param _data The initialization calldata to execute on the proxy
    /// @return _proxy The deployed proxy address
    function deployAndCall(address _implementation, bytes calldata _data) external payable returns (address _proxy);

    /// @notice Deploys a minimal ERC1967I proxy deterministically with a salt.
    /// @param _implementation The implementation contract address
    /// @param _salt The salt for deterministic deployment via CREATE2
    /// @return _proxy The deployed proxy address
    function deployDeterministic(address _implementation, bytes32 _salt) external returns (address _proxy);

    /// @notice Deploys a minimal ERC1967I proxy deterministically and calls it with initialization data.
    /// @param _implementation The implementation contract address
    /// @param _salt The salt for deterministic deployment via CREATE2
    /// @param _data The initialization calldata to execute on the proxy
    /// @return _proxy The deployed proxy address
    function deployDeterministicAndCall(
        address _implementation,
        bytes32 _salt,
        bytes calldata _data
    )
        external
        payable
        returns (address _proxy);

    /// @notice Predicts the deterministic address for a proxy.
    /// @param _implementation The implementation contract address
    /// @param _salt The salt for deterministic deployment
    /// @return The predicted proxy address
    function predictDeterministicAddress(address _implementation, bytes32 _salt) external view returns (address);

    /// @notice Returns the init code hash for deterministic deployment.
    /// @param _implementation The implementation contract address
    /// @return The init code hash
    function initCodeHash(address _implementation) external pure returns (bytes32);
}

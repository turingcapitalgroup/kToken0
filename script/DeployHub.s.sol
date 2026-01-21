// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { kOFTAdapter } from "../src/kOFTAdapter.sol";
import { kToken } from "../src/kToken.sol";

import { DeploymentManager } from "./DeploymentManager.s.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { console2 } from "forge-std/Script.sol";

/// @title DeployHub
/// @notice Deploys kToken + kOFTAdapter for mainnet (hub) deployment
/// @dev This is used for the mainnet hub where tokens are locked/released via kOFTAdapter
contract DeployHub is DeploymentManager {
    kToken public token;
    kOFTAdapter public koftAdapter;

    string public name;
    string public symbol;
    uint8 public decimals;

    function run() public {
        // Read network configuration
        NetworkConfig memory config = readNetworkConfig();
        validateConfig(config);
        logConfig(config);

        // Token configuration
        name = "kUSD Token";
        symbol = "kUSD";
        decimals = 6; // USDC decimals

        vm.startBroadcast();

        // Check if we should use existing kToken or deploy new one
        if (config.existingKToken != address(0)) {
            // Use existing kToken
            console2.log("=== Using Existing kToken (Hub) ===");
            token = kToken(config.existingKToken);
            console2.log("Using existing kToken at:", address(token));
        } else {
            // Deploy new kToken via proxy
            console2.log("=== Deploying kToken (Hub) ===");
            kToken tokenImplementation = new kToken();
            bytes memory tokenInitData = abi.encodeCall(
                kToken.initialize,
                (
                    config.roles.owner,
                    config.roles.admin,
                    config.roles.emergencyAdmin,
                    msg.sender, // temporary minter
                    name,
                    symbol,
                    decimals
                )
            );
            ERC1967Proxy tokenProxy = new ERC1967Proxy(address(tokenImplementation), tokenInitData);
            token = kToken(address(tokenProxy));
            console2.log("kToken implementation:", address(tokenImplementation));
            console2.log("kToken proxy deployed at:", address(token));
        }

        // Step 2: Deploy kOFTAdapter (Hub uses adapter for locking/releasing)
        console2.log("=== Deploying kOFTAdapter (Hub) ===");
        kOFTAdapter adapterImplementation = new kOFTAdapter(address(token), config.layerZero.lzEndpoint);
        bytes memory adapterData = abi.encodeWithSelector(kOFTAdapter.initialize.selector, config.roles.owner);
        ERC1967Proxy adapterProxy = new ERC1967Proxy(address(adapterImplementation), adapterData);
        koftAdapter = kOFTAdapter(address(adapterProxy));
        console2.log("kOFTAdapter implementation:", address(adapterImplementation));
        console2.log("kOFTAdapter proxy deployed at:", address(koftAdapter));

        // Step 3: Grant kOFTAdapter the MINTER_ROLE on kToken
        console2.log("=== Granting MINTER_ROLE to kOFTAdapter ===");
        token.grantMinterRole(address(koftAdapter));
        console2.log("kOFTAdapter granted MINTER_ROLE on kToken");

        // Step 4: Remove MINTER_ROLE from deployer for security
        try token.revokeMinterRole(msg.sender) {
            console2.log("Removed MINTER_ROLE from deployer");
        } catch {
            console2.log("Deployer did not have MINTER_ROLE or revocation failed");
        }

        // Write all deployment addresses
        writeContractAddress("kToken", address(token));
        writeContractAddress("kOFTAdapter", address(koftAdapter));
        writeContractAddress("kOFTAdapterImplementation", address(adapterImplementation));

        // Summary
        console2.log("=== Hub Deployment Summary ===");
        console2.log("Network: Hub (Mainnet)");
        if (config.existingKToken != address(0)) {
            console2.log("kToken: (existing)", address(token));
        } else {
            console2.log("kToken: (new)", address(token));
        }
        console2.log("kOFTAdapter:", address(koftAdapter));
        console2.log("LayerZero Endpoint:", config.layerZero.lzEndpoint);
        console2.log("LayerZero EID:", config.layerZero.lzEid);
        console2.log("Owner:", config.roles.owner);
        console2.log("Admin:", config.roles.admin);
        console2.log("Emergency Admin:", config.roles.emergencyAdmin);
        console2.log("Architecture: Hub - Tokens locked/released via kOFTAdapter");

        vm.stopBroadcast();
    }
}

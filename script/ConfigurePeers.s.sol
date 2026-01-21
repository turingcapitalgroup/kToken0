// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import { IOAppCore } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppCore.sol";

import { DeploymentManager } from "./DeploymentManager.s.sol";
import { console2 } from "forge-std/Script.sol";

/// @title ConfigurePeers
/// @notice Configures OFT peers between chains for crosschain communication
/// @dev This script sets up the peer relationships between kOFT/kOFTAdapter deployments on different chains.
/// Must be run on each chain to establish bidirectional communication.
///
/// Usage:
/// 1. Deploy kOFT on all chains first (hub and spokes)
/// 2. Run this script on each chain to set peers
/// 3. Peers must be set on BOTH sides for crosschain transfers to work
///
/// Example for Hub <-> Spoke:
/// - On Hub (EID 30101): setPeer(30110, spokeOFTAddress)  // Arbitrum
/// - On Spoke (EID 30110): setPeer(30101, hubOFTAddress)  // Ethereum
contract ConfigurePeers is DeploymentManager {
    /// @notice Peer configuration structure
    struct PeerConfig {
        uint32 eid; // LayerZero endpoint ID
        address peer; // OFT address on that chain
    }

    function run() public {
        // Read network configuration
        NetworkConfig memory config = readNetworkConfig();
        validateConfig(config);

        // Read existing deployment
        DeploymentOutput memory existing = readDeploymentOutput();
        require(existing.contracts.kOFT != address(0), "kOFT not deployed on this chain");

        console2.log("=== Configuring Peers ===");
        console2.log("Local kOFT:", existing.contracts.kOFT);
        console2.log("Local EID:", config.layerZero.lzEid);

        // Read peer configurations from environment or config
        // Format: PEER_<EID>=<address>
        // Example: PEER_30110=0x1234...
        PeerConfig[] memory peers = _readPeerConfigs();

        if (peers.length == 0) {
            console2.log("No peers configured. Set PEER_<EID>=<address> environment variables.");
            console2.log("Example: PEER_30110=0x1234567890123456789012345678901234567890");
            return;
        }

        vm.startBroadcast();

        IOAppCore oft = IOAppCore(existing.contracts.kOFT);

        for (uint256 i = 0; i < peers.length; i++) {
            console2.log("Setting peer for EID:", peers[i].eid);
            console2.log("  Peer address:", peers[i].peer);

            bytes32 peerBytes = bytes32(uint256(uint160(peers[i].peer)));
            oft.setPeer(peers[i].eid, peerBytes);

            console2.log("  Peer set successfully");
        }

        vm.stopBroadcast();

        console2.log("=== Peer Configuration Complete ===");
        console2.log("Configured", peers.length, "peers");
    }

    /// @notice Sets a single peer (convenience function)
    /// @param _localOft Address of the local kOFT
    /// @param _remoteEid LayerZero endpoint ID of the remote chain
    /// @param _remotePeer Address of the kOFT on the remote chain
    function setPeer(address _localOft, uint32 _remoteEid, address _remotePeer) public {
        console2.log("=== Setting Single Peer ===");
        console2.log("Local kOFT:", _localOft);
        console2.log("Remote EID:", _remoteEid);
        console2.log("Remote Peer:", _remotePeer);

        vm.startBroadcast();

        IOAppCore oft = IOAppCore(_localOft);
        bytes32 peerBytes = bytes32(uint256(uint160(_remotePeer)));
        oft.setPeer(_remoteEid, peerBytes);

        vm.stopBroadcast();

        console2.log("Peer set successfully");
    }

    /// @notice Reads peer configurations from environment variables
    /// @dev Looks for PEER_<EID>=<address> format
    function _readPeerConfigs() internal view returns (PeerConfig[] memory) {
        // Common LayerZero V2 endpoint IDs
        uint32[10] memory commonEids = [
            uint32(30_101), // Ethereum
            uint32(30_102), // BSC
            uint32(30_106), // Avalanche
            uint32(30_109), // Polygon
            uint32(30_110), // Arbitrum
            uint32(30_111), // Optimism
            uint32(30_112), // Fantom
            uint32(30_184), // Base
            uint32(30_214), // Scroll
            uint32(30_243) // Blast
        ];

        // Count configured peers
        uint256 count = 0;
        for (uint256 i = 0; i < commonEids.length; i++) {
            string memory envKey = string.concat("PEER_", vm.toString(commonEids[i]));
            address peer = vm.envOr(envKey, address(0));
            if (peer != address(0)) {
                count++;
            }
        }

        // Build peer array
        PeerConfig[] memory peers = new PeerConfig[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < commonEids.length; i++) {
            string memory envKey = string.concat("PEER_", vm.toString(commonEids[i]));
            address peer = vm.envOr(envKey, address(0));
            if (peer != address(0)) {
                peers[index] = PeerConfig({ eid: commonEids[i], peer: peer });
                index++;
            }
        }

        return peers;
    }
}

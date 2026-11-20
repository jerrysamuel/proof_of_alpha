// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import "../src/ProofOfAlpha.sol";

contract Deploy is Script {
    function run() external returns (ProofOfAlpha deployed) {
        address agent = vm.envAddress("AGENT_ID_ADDRESS");
        vm.startBroadcast();
        deployed = new ProofOfAlpha(agent);
        vm.stopBroadcast();
        console2.logAddress(address(deployed));
    }
}

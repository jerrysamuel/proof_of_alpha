// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import "../src/ProofOfAlpha.sol";

contract AddFeed is Script {
    function run() external {
        ProofOfAlpha poa = ProofOfAlpha(vm.envAddress("POA_ADDRESS"));
        bytes32 asset = bytes32(bytes(vm.envString("ASSET")));
        address feed = vm.envAddress("FEED_ADDRESS");
        uint32 stale = uint32(vm.envUint("MAX_STALENESS"));
        vm.startBroadcast();
        poa.addFeed(asset, feed, stale);
        vm.stopBroadcast();
    }
}

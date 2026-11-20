// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

interface ForkFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

contract ProofOfAlphaForkTest is Test {
    function testForkReadsConfiguredChainlinkFeed() public {
        string memory rpc = vm.envOr("RPC_URL", string(""));
        address feed = vm.envOr("CHAINLINK_FEED_ADDRESS", address(0));
        if (bytes(rpc).length == 0 || feed == address(0)) {
            vm.skip(true);
        }
        vm.createSelectFork(rpc);
        (, int256 answer,, uint256 updatedAt,) = ForkFeed(feed).latestRoundData();
        assertGt(answer, 0);
        assertGt(updatedAt, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Test.sol";
import "../src/ProofOfAlpha.sol";
import "./MockAgentID.sol";
import "./MockFeed.sol";

contract ProofOfAlphaTest is Test {
    ProofOfAlpha poa;
    MockAgentID agent;
    MockFeed feed;
    address caller = address(0xBEEF);
    bytes32 asset = bytes32("BTC");

    function setUp() public {
        vm.warp(1000);
        agent = new MockAgentID();
        feed = new MockFeed();
        poa = new ProofOfAlpha(address(agent));
        feed.setRound(1, 100e8, 1000);
        poa.addFeed(asset, address(feed), 1 days);
        agent.setBalance(caller, 1);
    }

    function testDeploymentAndOwner() public {
        assertEq(poa.owner(), address(this));
        assertEq(address(poa.agentId()), address(agent));
    }

    function testZeroAgentIdReverts() public {
        vm.expectRevert(ProofOfAlpha.ZeroAddress.selector);
        new ProofOfAlpha(address(0));
    }

    function testOwnerFunctionsAndFeedImmutability() public {
        vm.expectRevert(ProofOfAlpha.NotOwner.selector);
        vm.prank(caller);
        poa.addFeed(bytes32("ETH"), address(feed), 1 days);
        vm.expectRevert(ProofOfAlpha.NotOwner.selector);
        vm.prank(caller);
        poa.setAssetEnabled(asset, false);
        vm.expectRevert(ProofOfAlpha.ZeroAddress.selector);
        poa.addFeed(bytes32("ETH"), address(0), 1 days);
        vm.expectRevert(ProofOfAlpha.AssetExists.selector);
        poa.addFeed(asset, address(feed), 1 days);
        poa.setAssetEnabled(asset, false);
        vm.expectRevert(ProofOfAlpha.AssetNotAllowed.selector);
        vm.prank(caller);
        poa.postCall(asset, true, 1 hours);
        poa.setAssetEnabled(asset, true);
        address next = address(0xCAFE);
        poa.transferOwnership(next);
        assertEq(poa.owner(), next);
        vm.prank(next);
        poa.renounceOwnership();
        assertEq(poa.owner(), address(0));
    }

    function testOnlyAgentCanPost() public {
        vm.expectRevert(ProofOfAlpha.NotAgentID.selector);
        poa.postCall(asset, true, 1 hours);
    }

    function testUnknownAssetAndUnknownCallRevert() public {
        vm.expectRevert(ProofOfAlpha.AssetNotAllowed.selector);
        vm.prank(caller);
        poa.postCall(bytes32("ETH"), true, 1 hours);
        vm.expectRevert(ProofOfAlpha.UnknownCall.selector);
        poa.getCall(99);
    }

    function testBadDurationsAndPricesRevert() public {
        vm.expectRevert(ProofOfAlpha.BadDuration.selector);
        vm.prank(caller);
        poa.postCall(asset, true, 3599);
        vm.expectRevert(ProofOfAlpha.BadDuration.selector);
        vm.prank(caller);
        poa.postCall(asset, true, 30 days + 1);
        feed.setRound(2, 0, 1000);
        vm.expectRevert(ProofOfAlpha.StalePrice.selector);
        vm.prank(caller);
        poa.postCall(asset, true, 1 hours);
        feed.setRound(3, 100e8, 1);
        vm.warp(100000);
        vm.expectRevert(ProofOfAlpha.StalePrice.selector);
        vm.prank(caller);
        poa.postCall(asset, true, 1 hours);
    }

    function testOpenCallLimit() public {
        vm.startPrank(caller);
        for (uint256 i = 0; i < 20; i++) poa.postCall(asset, true, 1 hours);
        vm.expectRevert(ProofOfAlpha.TooManyOpenCalls.selector);
        poa.postCall(asset, true, 1 hours);
        vm.stopPrank();
    }

    function testPostAndResolveLongWin() public {
        vm.expectEmit(true, true, true, true);
        emit ProofOfAlpha.CallPosted(0, caller, asset, true, 100e8, 4600);
        vm.prank(caller);
        uint256 id = poa.postCall(asset, true, 1 hours);
        assertEq(id, 0);
        ProofOfAlpha.Call memory c = poa.getCall(id);
        assertEq(c.caller, caller);
        assertEq(c.entryPrice, 100e8);
        vm.warp(4600);
        feed.setRound(2, 110e8, 4600);
        poa.resolve(id, 2);
        vm.expectRevert(ProofOfAlpha.AlreadyResolved.selector);
        poa.resolve(id, 2);
        (uint32 total, uint32 wins,, uint32 open, int256 cumulative) = poa.stats(caller);
        assertEq(total, 1);
        assertEq(wins, 1);
        assertEq(open, 0);
        assertEq(cumulative, 1000);
    }

    function testFlatIsLoss() public {
        vm.prank(caller);
        uint256 id = poa.postCall(asset, true, 1 hours);
        vm.warp(4600);
        feed.setRound(2, 100e8, 4600);
        poa.resolve(id, 2);
        (,, uint32 losses,,) = poa.stats(caller);
        assertEq(losses, 1);
    }

    function testShortWinAndLoss() public {
        vm.prank(caller);
        uint256 win = poa.postCall(asset, false, 1 hours);
        vm.warp(4600);
        feed.setRound(2, 90e8, 4600);
        poa.resolve(win, 2);
        (uint32 totalAfterWin, uint32 winsAfterWin,, uint32 openAfterWin, int256 cumulativeAfterWin) = poa.stats(caller);
        assertEq(totalAfterWin, 1);
        assertEq(winsAfterWin, 1);
        assertEq(openAfterWin, 0);
        assertEq(cumulativeAfterWin, 1000);
        vm.warp(5000);
        feed.setRound(3, 90e8, 5000);
        vm.prank(caller);
        uint256 loss = poa.postCall(asset, false, 1 hours);
        vm.warp(8600);
        feed.setRound(4, 100e8, 8600);
        poa.resolve(loss, 4);
        (,, uint32 losses,,) = poa.stats(caller);
        assertEq(losses, 1);
    }

    function testLongLoss() public {
        vm.prank(caller);
        uint256 id = poa.postCall(asset, true, 1 hours);
        vm.warp(4600);
        feed.setRound(2, 90e8, 4600);
        poa.resolve(id, 2);
        (,, uint32 losses, uint32 open, int256 cumulative) = poa.stats(caller);
        assertEq(losses, 1);
        assertEq(open, 0);
        assertEq(cumulative, -1000);
    }

    function testResolvedEventFields() public {
        vm.prank(caller);
        uint256 id = poa.postCall(asset, false, 1 hours);
        vm.warp(4600);
        feed.setRound(2, 90e8, 4600);
        vm.expectEmit(true, true, false, true);
        emit ProofOfAlpha.CallResolved(id, caller, 90e8, 1000, true);
        poa.resolve(id, 2);
    }

    function testFuzzStatsInvariant(uint8 requestedPosts, uint8 requestedResolutions) public {
        uint256 postCount = bound(uint256(requestedPosts), 0, 20);
        uint256 resolveCount = bound(uint256(requestedResolutions), 0, postCount);
        vm.startPrank(caller);
        for (uint256 i = 0; i < postCount; i++) {
            feed.setRound(uint80(10 + i), 100e8, block.timestamp);
            poa.postCall(asset, i % 2 == 0, 1 hours);
        }
        vm.stopPrank();
        (uint32 totalBefore, uint32 winsBefore, uint32 lossesBefore, uint32 openBefore,) = poa.stats(caller);
        assertEq(uint256(winsBefore + lossesBefore + openBefore), totalBefore);
        vm.warp(4600);
        feed.setRound(100, 110e8, 4600);
        for (uint256 i = 0; i < resolveCount; i++) poa.resolve(i, 100);
        (uint32 totalAfter, uint32 winsAfter, uint32 lossesAfter, uint32 openAfter,) = poa.stats(caller);
        assertEq(uint256(winsAfter + lossesAfter + openAfter), totalAfter);
    }

    function testFuzzEntryAndExitPrices(uint64 rawEntry, uint64 rawExit) public {
        uint256 entry = bound(uint256(rawEntry), 1, 1e18);
        uint256 exit = bound(uint256(rawExit), 1, 1e18);
        feed.setRound(2, int256(entry), 1000);
        vm.prank(caller);
        uint256 id = poa.postCall(asset, true, 1 hours);
        vm.warp(4600);
        feed.setRound(3, int256(exit), 4600);
        poa.resolve(id, 3);
        int256 expected = (int256(exit) - int256(entry)) * 10000 / int256(entry);
        ProofOfAlpha.Call memory c = poa.getCall(id);
        assertEq(c.returnBps, expected);
    }

    function testResolveGuardsAndFirstRoundRule() public {
        vm.prank(caller);
        uint256 id = poa.postCall(asset, true, 1 hours);
        vm.expectRevert(ProofOfAlpha.UnknownCall.selector);
        poa.resolve(99, 2);
        vm.expectRevert(ProofOfAlpha.NotExpired.selector);
        poa.resolve(id, 1);
        vm.warp(4600);
        feed.setRound(2, 110e8, 3000);
        vm.expectRevert(ProofOfAlpha.BadRound.selector);
        poa.resolve(id, 2);
        feed.setRound(3, 111e8, 4600);
        feed.setRound(4, 112e8, 4601);
        vm.expectRevert(ProofOfAlpha.NotFirstRound.selector);
        poa.resolve(id, 4);
        poa.resolve(id, 3);
        vm.expectRevert(ProofOfAlpha.AlreadyResolved.selector);
        poa.resolve(id, 3);
    }

    function testNonPositiveExitAndPhaseStartRound() public {
        vm.prank(caller);
        uint256 id = poa.postCall(asset, true, 1 hours);
        vm.warp(4600);
        feed.setRound(2, 0, 4600);
        vm.expectRevert(ProofOfAlpha.BadRound.selector);
        poa.resolve(id, 2);
        vm.warp(5000);
        feed.setRound(3, 100e8, 5000);
        vm.prank(caller);
        uint256 phaseId = poa.postCall(asset, true, 1 hours);
        vm.warp(8600);
        uint80 phaseRound = uint80((uint256(1) << 64) + 1);
        feed.setRound(phaseRound, 110e8, 8600);
        poa.resolve(phaseId, phaseRound);
    }

    function testDisabledAssetKeepsExistingCallResolvable() public {
        vm.prank(caller);
        uint256 id = poa.postCall(asset, true, 1 hours);
        poa.setAssetEnabled(asset, false);
        vm.warp(4600);
        feed.setRound(2, 110e8, 4600);
        poa.resolve(id, 2);
        assertEq(poa.totalCalls(), 1);
    }

    function testViewsAndPagination() public {
        vm.startPrank(caller);
        poa.postCall(asset, true, 1 hours);
        poa.postCall(asset, false, 1 hours);
        vm.stopPrank();
        assertEq(poa.callCountOf(caller), 2);
        assertEq(poa.assetsLength(), 1);
        uint256[] memory first = poa.getCallIds(caller, 0, 1);
        assertEq(first.length, 1);
        assertEq(first[0], 0);
        uint256[] memory rest = poa.getCallIds(caller, 1, 10);
        assertEq(rest.length, 1);
        assertEq(rest[0], 1);
        uint256[] memory empty = poa.getCallIds(caller, 9, 1);
        assertEq(empty.length, 0);
    }
}

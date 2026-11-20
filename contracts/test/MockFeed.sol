// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockFeed {
    struct Round {
        int256 answer;
        uint256 updatedAt;
    }
    mapping(uint80 => Round) public rounds;
    uint80 public latest;

    function setRound(uint80 id, int256 answer, uint256 updatedAt) external {
        rounds[id] = Round(answer, updatedAt);
        if (id > latest) latest = id;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        Round memory r = rounds[latest];
        return (latest, r.answer, 0, r.updatedAt, latest);
    }

    function getRoundData(uint80 id) external view returns (uint80, int256, uint256, uint256, uint80) {
        Round memory r = rounds[id];
        require(r.updatedAt != 0, "No data present");
        return (id, r.answer, 0, r.updatedAt, id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAgentID {
    function balanceOf(address account) external view returns (uint256);
}

interface IPriceFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
    function getRoundData(uint80) external view returns (uint80, int256, uint256, uint256, uint80);
}

contract ProofOfAlpha {
    error NotOwner();
    error ZeroAddress();
    error NotAgentID();
    error AssetExists();
    error AssetNotAllowed();
    error BadDuration();
    error TooManyOpenCalls();
    error StalePrice();
    error UnknownCall();
    error NotExpired();
    error AlreadyResolved();
    error BadRound();
    error NotFirstRound();
    enum Status {
        Open,
        Resolved
    }

    struct Feed {
        IPriceFeed source;
        uint32 maxStaleness;
        bool exists;
        bool enabled;
    }

    struct Call {
        address caller;
        bytes32 asset;
        bool isLong;
        Status status;
        uint64 openedAt;
        uint64 expiresAt;
        int256 entryPrice;
        int256 exitPrice;
        int256 returnBps;
    }

    struct Stats {
        uint32 total;
        uint32 wins;
        uint32 losses;
        uint32 open;
        int256 cumulativeReturnBps;
    }
    IAgentID public immutable agentId;
    address public owner;
    uint64 public constant MIN_DURATION = 1 hours;
    uint64 public constant MAX_DURATION = 30 days;
    uint32 public constant MAX_OPEN_CALLS = 20;
    mapping(bytes32 => Feed) public feeds;
    bytes32[] public assets;
    Call[] private _calls;
    mapping(address => uint256[]) private _callIdsOf;
    mapping(address => Stats) public stats;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FeedAdded(bytes32 indexed asset, address indexed source, uint32 maxStaleness);
    event AssetEnabled(bytes32 indexed asset, bool enabled);
    event CallPosted(
        uint256 indexed id,
        address indexed caller,
        bytes32 indexed asset,
        bool isLong,
        int256 entryPrice,
        uint64 expiresAt
    );
    event CallResolved(uint256 indexed id, address indexed caller, int256 exitPrice, int256 returnBps, bool won);
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address agentId_) {
        if (agentId_ == address(0)) revert ZeroAddress();
        agentId = IAgentID(agentId_);
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function addFeed(bytes32 asset, address source, uint32 maxStaleness) external onlyOwner {
        if (source == address(0)) revert ZeroAddress();
        if (feeds[asset].exists) revert AssetExists();
        feeds[asset] = Feed(IPriceFeed(source), maxStaleness, true, true);
        assets.push(asset);
        emit FeedAdded(asset, source, maxStaleness);
    }

    function setAssetEnabled(bytes32 asset, bool enabled) external onlyOwner {
        if (!feeds[asset].exists) revert AssetNotAllowed();
        feeds[asset].enabled = enabled;
        emit AssetEnabled(asset, enabled);
    }

    function postCall(bytes32 asset, bool isLong, uint64 duration) external returns (uint256 id) {
        if (agentId.balanceOf(msg.sender) == 0) revert NotAgentID();
        Feed memory f = feeds[asset];
        if (!f.enabled) revert AssetNotAllowed();
        if (duration < MIN_DURATION || duration > MAX_DURATION) revert BadDuration();
        Stats storage s = stats[msg.sender];
        if (s.open >= MAX_OPEN_CALLS) revert TooManyOpenCalls();
        (, int256 price,, uint256 updatedAt,) = f.source.latestRoundData();
        if (price <= 0 || updatedAt + f.maxStaleness < block.timestamp) revert StalePrice();
        uint64 openedAt = uint64(block.timestamp);
        uint64 expiresAt = openedAt + duration;
        id = _calls.length;
        _calls.push(Call(msg.sender, asset, isLong, Status.Open, openedAt, expiresAt, price, 0, 0));
        _callIdsOf[msg.sender].push(id);
        s.total += 1;
        s.open += 1;
        emit CallPosted(id, msg.sender, asset, isLong, price, expiresAt);
    }

    function resolve(uint256 id, uint80 roundId) external {
        if (id >= _calls.length) revert UnknownCall();
        Call storage c = _calls[id];
        if (c.status != Status.Open) revert AlreadyResolved();
        if (block.timestamp < c.expiresAt) revert NotExpired();
        IPriceFeed src = feeds[c.asset].source;
        (, int256 price,, uint256 updatedAt,) = src.getRoundData(roundId);
        if (price <= 0 || updatedAt < c.expiresAt) revert BadRound();
        try src.getRoundData(roundId - 1) returns (uint80, int256, uint256, uint256 prevUpdatedAt, uint80) {
            if (prevUpdatedAt != 0 && prevUpdatedAt >= c.expiresAt) revert NotFirstRound();
        } catch {}
        int256 moveBps = ((price - c.entryPrice) * 10000) / c.entryPrice;
        int256 ret = c.isLong ? moveBps : -moveBps;
        bool won = ret > 0;
        c.status = Status.Resolved;
        c.exitPrice = price;
        c.returnBps = ret;
        Stats storage s = stats[c.caller];
        s.open -= 1;
        if (won) s.wins += 1;
        else s.losses += 1;
        s.cumulativeReturnBps += ret;
        emit CallResolved(id, c.caller, price, ret, won);
    }

    function getCall(uint256 id) external view returns (Call memory) {
        if (id >= _calls.length) revert UnknownCall();
        return _calls[id];
    }

    function totalCalls() external view returns (uint256) {
        return _calls.length;
    }

    function assetsLength() external view returns (uint256) {
        return assets.length;
    }

    function callCountOf(address caller) external view returns (uint256) {
        return _callIdsOf[caller].length;
    }

    function hasAgentID(address account) external view returns (bool) {
        return agentId.balanceOf(account) > 0;
    }

    function getCallIds(address caller, uint256 offset, uint256 limit) external view returns (uint256[] memory ids) {
        uint256[] storage all = _callIdsOf[caller];
        if (offset >= all.length) return new uint256[](0);
        uint256 end = offset + limit;
        if (end > all.length) end = all.length;
        ids = new uint256[](end - offset);
        for (uint256 i = offset; i < end; i++) ids[i - offset] = all[i];
    }
}

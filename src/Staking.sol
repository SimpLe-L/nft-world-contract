// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFTStaking is ERC721Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct RewardPool {
        uint256 totalReward; // 奖励总量
        uint256 claimed; // 已领取数量
        uint256 unlockStart; // 解锁起始时间戳
    }

    IERC721 public immutable nftToken; // 质押的NFT合约
    IERC20 public immutable rewardToken; // 奖励代币合约
    uint256 public rewardRatePerSecond; // 每秒奖励率（每NFT）

    mapping(address => mapping(uint256 => uint256)) private _stakeTimestamps; // 质押时间记录
    mapping(address => RewardPool[]) private _rewardPools; // 用户奖励池

    constructor(address _nft, address _rewardToken, uint256 _dailyRewardRate) {
        nftToken = IERC721(_nft);
        rewardToken = IERC20(_rewardToken);
        rewardRatePerSecond = _dailyRewardRate / 86400; // 将日奖励率转换为每秒
    }

    // 质押NFT
    function stake(uint256 tokenId) external nonReentrant {
        require(
            _stakeTimestamps[msg.sender][tokenId] == 0,
            "Token already staked"
        );
        nftToken.safeTransferFrom(msg.sender, address(this), tokenId);
        _stakeTimestamps[msg.sender][tokenId] = block.timestamp;
    }

    // 取消质押并计算奖励
    function unstake(uint256 tokenId) external nonReentrant {
        uint256 stakeTime = _stakeTimestamps[msg.sender][tokenId];
        require(stakeTime != 0, "Token not staked");

        // 计算质押时长和奖励
        uint256 stakedDuration = block.timestamp - stakeTime;
        uint256 reward = stakedDuration * rewardRatePerSecond;

        // 转移NFT回用户
        nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
        delete _stakeTimestamps[msg.sender][tokenId];

        // 创建新的奖励池
        _rewardPools[msg.sender].push(
            RewardPool({
                totalReward: reward,
                claimed: 0,
                unlockStart: block.timestamp
            })
        );
    }

    // 领取可解锁的奖励
    function claimRewards() external nonReentrant {
        uint256 totalClaimable;
        RewardPool[] storage pools = _rewardPools[msg.sender];

        for (uint256 i = 0; i < pools.length; i++) {
            RewardPool storage pool = pools[i];
            if (pool.unlockStart == 0 || pool.claimed >= pool.totalReward)
                continue;

            uint256 elapsed = block.timestamp - pool.unlockStart;
            uint256 vestingPeriod = 30 days;

            if (elapsed >= vestingPeriod) {
                totalClaimable += pool.totalReward - pool.claimed;
                pool.claimed = pool.totalReward;
            } else {
                uint256 vestedAmount = (pool.totalReward * elapsed) /
                    vestingPeriod;
                uint256 claimable = vestedAmount - pool.claimed;
                if (claimable > 0) {
                    totalClaimable += claimable;
                    pool.claimed += claimable;
                }
            }
        }

        require(totalClaimable > 0, "No claimable rewards");
        rewardToken.safeTransfer(msg.sender, totalClaimable);
    }

    // 查询可领取奖励（视图函数）
    function getClaimableRewards(address user) external view returns (uint256) {
        uint256 totalClaimable;
        RewardPool[] storage pools = _rewardPools[user];

        for (uint256 i = 0; i < pools.length; i++) {
            RewardPool storage pool = pools[i];
            if (pool.unlockStart == 0 || pool.claimed >= pool.totalReward)
                continue;

            uint256 elapsed = block.timestamp - pool.unlockStart;
            uint256 vestingPeriod = 30 days;

            if (elapsed >= vestingPeriod) {
                totalClaimable += pool.totalReward - pool.claimed;
            } else {
                uint256 vestedAmount = (pool.totalReward * elapsed) /
                    vestingPeriod;
                totalClaimable += vestedAmount - pool.claimed;
            }
        }
        return totalClaimable;
    }
}

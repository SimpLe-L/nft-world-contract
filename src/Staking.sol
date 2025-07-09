// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFTStaking is ERC721Holder, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct StakeInfo {
        address staker;
        uint256 timestamp;
    }

    struct RewardPool {
        uint256 totalReward;
        uint256 claimed;
        uint256 unlockStart;
    }

    IERC721 public immutable nftToken;
    IERC20 public immutable rewardToken;
    uint256 public rewardRatePerSecond;

    mapping(uint256 => StakeInfo) public stakeInfos;
    mapping(address => RewardPool[]) private _rewardPools;

    uint256 public constant VESTING_DURATION = 30 days;

    constructor(
        address _nft,
        address _rewardToken,
        uint256 _dailyRewardRate
    ) Ownable(msg.sender) {
        nftToken = IERC721(_nft);
        rewardToken = IERC20(_rewardToken);
        rewardRatePerSecond = _dailyRewardRate / 86400;
    }

    // stakiing

    function stake(uint256 tokenId) public nonReentrant {
        require(stakeInfos[tokenId].staker == address(0), "Already staked");

        nftToken.safeTransferFrom(msg.sender, address(this), tokenId);
        stakeInfos[tokenId] = StakeInfo({
            staker: msg.sender,
            timestamp: block.timestamp
        });
    }

    function stakeBatch(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stake(tokenIds[i]);
        }
    }

    function unstake(uint256 tokenId) public nonReentrant {
        StakeInfo memory info = stakeInfos[tokenId];
        require(info.staker == msg.sender, "Not staker");

        uint256 stakedTime = block.timestamp - info.timestamp;
        uint256 reward = stakedTime * rewardRatePerSecond;

        delete stakeInfos[tokenId];

        // transfer NFT
        nftToken.safeTransferFrom(address(this), msg.sender, tokenId);

        // reward pool
        _rewardPools[msg.sender].push(
            RewardPool({
                totalReward: reward,
                claimed: 0,
                unlockStart: block.timestamp
            })
        );
    }

    function unstakeBatch(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            unstake(tokenIds[i]);
        }
    }

    // claim rewards

    function claimRewards() external nonReentrant {
        uint256 claimable = _calculateClaimable(msg.sender);
        require(claimable > 0, "Nothing to claim");

        uint256 available = rewardToken.balanceOf(address(this));
        require(available >= claimable, "Insufficient rewards in contract");

        rewardToken.safeTransfer(msg.sender, claimable);
    }

    function _calculateClaimable(
        address user
    ) internal returns (uint256 total) {
        RewardPool[] storage pools = _rewardPools[user];

        for (uint256 i = 0; i < pools.length; i++) {
            RewardPool storage pool = pools[i];
            if (pool.claimed >= pool.totalReward) continue;

            uint256 elapsed = block.timestamp - pool.unlockStart;
            uint256 vested = elapsed >= VESTING_DURATION
                ? pool.totalReward
                : (pool.totalReward * elapsed) / VESTING_DURATION;

            uint256 claimable = vested - pool.claimed;
            if (claimable > 0) {
                pool.claimed += claimable;
                total += claimable;
            }
        }
    }

    function getClaimableRewards(
        address user
    ) external view returns (uint256 total) {
        RewardPool[] storage pools = _rewardPools[user];
        for (uint256 i = 0; i < pools.length; i++) {
            RewardPool storage pool = pools[i];
            if (pool.claimed >= pool.totalReward) continue;

            uint256 elapsed = block.timestamp - pool.unlockStart;
            uint256 vested = elapsed >= VESTING_DURATION
                ? pool.totalReward
                : (pool.totalReward * elapsed) / VESTING_DURATION;

            total += vested - pool.claimed;
        }
    }

    function getUserRewardPools(
        address user
    ) external view returns (RewardPool[] memory) {
        return _rewardPools[user];
    }

    function getUserStakedTokens(
        address user,
        uint256 start,
        uint256 end
    ) external view returns (uint256[] memory tokenIds) {
        uint256 count = 0;
        uint256[] memory tmp = new uint256[](end - start + 1);
        for (uint256 i = start; i <= end; i++) {
            if (stakeInfos[i].staker == user) {
                tmp[count++] = i;
            }
        }

        tokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            tokenIds[i] = tmp[i];
        }
    }

    // manager
    function setDailyRewardRate(uint256 dailyRate) external onlyOwner {
        rewardRatePerSecond = dailyRate / 86400;
    }

    function emergencyWithdrawERC20(
        address to,
        uint256 amount
    ) external onlyOwner {
        rewardToken.safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SMPFaucet is Ownable {
    using SafeERC20 for IERC20;

    error TimeIntervalNotEnough();

    error FaucetTokenNotEnough();

    event TokenClaim(address indexed receiver, uint256 indexed amount);

    IERC20 public token;

    uint256 immutable claimTime;

    uint256 immutable claimAmount;

    mapping(address => uint256) timeMapping;

    constructor(
        address _tokenAddress,
        uint256 _claimTime,
        uint256 _claimAmount,
        address _owner
    ) Ownable(_owner) {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_claimTime > 0, "Claim time must be > 0");
        require(_claimAmount > 0, "Claim amount must be > 0");

        claimTime = _claimTime;
        claimAmount = _claimAmount;
        token = IERC20(_tokenAddress);
    }

    function claim() external {
        if (block.timestamp < timeMapping[msg.sender] + claimTime) {
            revert TimeIntervalNotEnough();
        }

        if (token.balanceOf(address(this)) < claimAmount) {
            revert FaucetTokenNotEnough();
        }

        timeMapping[msg.sender] = block.timestamp;

        token.safeTransfer(msg.sender, claimAmount);

        emit TokenClaim(msg.sender, claimAmount);
    }

    function deposit(uint256 _amount) external onlyOwner {
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(address _to, uint256 _amount) external onlyOwner {
        token.safeTransfer(_to, _amount);
    }

    function getTimeMapping(address _addr) external view returns (uint256) {
        return timeMapping[_addr];
    }
}

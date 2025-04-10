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

    address public tokenAddress;

    uint256 public claimTime;

    uint256 immutable claimAmount;

    mapping(address => uint256) timeMapping;

    constructor(
        address _tokenAddress,
        uint256 _claimTime,
        uint256 _claimAmount,
        address _owner
    ) Ownable(_owner) {
        tokenAddress = _tokenAddress;
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

        token.safeTransfer(msg.sender, claimAmount);

        timeMapping[msg.sender] = block.timestamp;

        emit TokenClaim(msg.sender, claimAmount);
    }

    function deposit(uint256 _amount) external onlyOwner {
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function gettimeMapping(address _addr) external view returns (uint256) {
        return timeMapping[_addr];
    }
}

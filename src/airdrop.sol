// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SimpleAirdrop {
    using SafeERC20 for IERC20;

    event TokenClaimed(address account, uint256 amount);

    error InvalidAmount();
    error TokenAlreadyClaimed();
    error InvalidProof();

    IERC20 public immutable simpleToken;
    bytes32 private immutable merkleRoot;

    mapping(address => bool) public hasClaimed;

    constructor(bytes32 _merkleRoot, IERC20 _tokenAddress) {
        merkleRoot = _merkleRoot;
        simpleToken = _tokenAddress;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (amount == 0 || simpleToken.balanceOf(address(this)) < amount) {
            revert InvalidAmount();
        }

        if (hasClaimed[account]) {
            revert TokenAlreadyClaimed();
        }

        bytes32 leaf = keccak256(abi.encodePacked(account, amount));

        if (!MerkleProof.verify(merkleProof, merkleRoot, leaf)) {
            revert InvalidProof();
        }

        emit TokenClaimed(account, amount);
        simpleToken.safeTransfer(account, amount);
        hasClaimed[account] = true;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function getClaimState(address account) external view returns (bool) {
        return hasClaimed[account];
    }
}

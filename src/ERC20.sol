// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract SimpleToken is ERC20, ERC20Capped, Ownable {
    event MintToken(uint256 indexed amount);

    event BurnToken(uint256 indexed amount);

    constructor(
        address initialOwner,
        uint256 cap
    ) ERC20("simple", "SMP") ERC20Capped(cap) Ownable(initialOwner) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        emit MintToken(amount);
    }
    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
        emit BurnToken(amount);
    }
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }
}

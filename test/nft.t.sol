// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/Nft.sol";

contract MyNftTest is Test {
    MyNft public nft;
    address user = address(0x123);

    function setUp() public {
        nft = new MyNft();
    }

    function testMint() public {
        vm.prank(user);
        uint256 tokenId = nft.safeMint(user);

        assertEq(nft.ownerOf(tokenId), user);
        string memory uri = nft.tokenURI(tokenId);
        assert(bytes(uri).length > 0);
    }

    function testMultipleMint() public {
        vm.startPrank(user);
        for (uint i = 0; i < 5; i++) {
            nft.safeMint(user);
        }
        vm.stopPrank();

        MyNft.SimpleNft[] memory nfts = nft.getOwnerNfts(user);
        assertEq(nfts.length, 5);
        for (uint i = 0; i < nfts.length; i++) {
            assertEq(nfts[i].owner, user);
        }
    }

    function testMaxSupplyLimit() public {
        vm.startPrank(user);
        for (uint i = 0; i < 10000; i++) {
            nft.safeMint(user);
        }
        vm.expectRevert("Max supply reached");
        nft.safeMint(user);
        vm.stopPrank();
    }
}

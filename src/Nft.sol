// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract MyNft is ERC721, ERC721Enumerable, ERC721URIStorage {
    using Strings for uint256;

    uint256 private _nextTokenId;
    uint256 private constant MAX_SUPPLY = 10000;
    uint256 private constant MAX_TYPE = 10;

    struct SimpleNft {
        address owner;
        uint256 tokenId;
        string uri;
    }

    string private constant BASE_IPFS_URI =
        "https://turquoise-real-jellyfish-905.mypinata.cloud/ipfs/bafybeie5mr4jkmiekulbl3mq67o7vw6ziihm4egdasfzyd5vcbgufarlbi/";

    event Minted(address indexed to, uint256 tokenId, string tokenURI);

    constructor() ERC721("MyNFT", "MNT") {}

    function _randomId(
        address to,
        uint256 nonce
    ) internal view returns (uint256) {
        return
            (uint256(
                keccak256(
                    abi.encodePacked(
                        to,
                        block.timestamp,
                        block.prevrandao,
                        nonce
                    )
                )
            ) % MAX_TYPE) + 1;
    }

    function safeMint(address to) external returns (uint256) {
        require(_nextTokenId < MAX_SUPPLY, "Max supply reached");

        uint256 tokenId = _nextTokenId++;
        uint256 imageId = _randomId(to, tokenId);
        string memory uri = string(
            abi.encodePacked(BASE_IPFS_URI, imageId.toString(), ".png")
        );

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        emit Minted(to, tokenId, uri);
        return tokenId;
    }

    function getOwnerNfts(
        address owner
    ) external view returns (SimpleNft[] memory nfts) {
        uint balance = balanceOf(owner);
        nfts = new SimpleNft[](balance);
        for (uint i = 0; i < balance; i++) {
            uint tokenId = tokenOfOwnerByIndex(owner, i);
            nfts[i] = SimpleNft(owner, tokenId, tokenURI(tokenId));
        }
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

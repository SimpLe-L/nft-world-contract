// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract MyNft is ERC721, ERC721URIStorage, ERC721Enumerable {
    using Strings for uint256;
    uint256 private _nextTokenId;

    struct SimpleNft {
        address owner;
        uint256 tokenId;
        string uri;
    }

    constructor() ERC721("MyNFT", "MNT") {}

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://turquoise-real-jellyfish-905.mypinata.cloud/ipfs/bafybeicq2vb72wznqybo663ptmthuralk2ubwzwetl56zjphnylkqnqy3u/";
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _generateURI() internal view returns (string memory) {
        uint random = _random(10);
        return string(abi.encodePacked(random.toString(), ".png"));
    }

    function _random(uint _max) internal view returns (uint256) {
        uint random = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.timestamp,
                    block.coinbase,
                    gasleft()
                )
            )
        );
        return (random % _max);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721URIStorage, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

    function safeMint(address to) public returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        string memory uriPart = _generateURI();
        string memory uri = string(abi.encodePacked(_baseURI(), uriPart));

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        return tokenId;
    }

    function getOwnerNfts(
        address _owner
    ) public view returns (SimpleNft[] memory ownerNft) {
        uint balance = balanceOf(_owner);
        ownerNft = new SimpleNft[](balance);
        for (uint i = 0; i < balance; i++) {
            uint tokenId = tokenOfOwnerByIndex(_owner, i);
            ownerNft[i] = SimpleNft({
                owner: _owner,
                tokenId: tokenId,
                uri: tokenURI(tokenId)
            });
        }
    }
}

// pragma solidity ^0.8.22;

// import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// contract MyNft is ERC721, ERC721URIStorage {
//     using Strings for uint256;
//     uint256 private _nextTokenId;

//     SimpleNft[] public nfts;
//     struct SimpleNft {
//         address owner;
//         uint tokenId;
//         string uri;
//     }

//     constructor() ERC721("MyNFT", "MNT") {}

//     function _baseURI() internal pure override returns (string memory) {
//         return
//             "https://turquoise-real-jellyfish-905.mypinata.cloud/ipfs/bafybeicq2vb72wznqybo663ptmthuralk2ubwzwetl56zjphnylkqnqy3u/";
//     }
//     function tokenURI(
//         uint256 tokenId
//     ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
//         return super.tokenURI(tokenId);
//     }

//     function setURI() internal view returns (string memory uri) {
//         uint random = _random(10);
//         uri = string(abi.encodePacked(random.toString(), ".png"));
//     }
//     function _random(uint _max) internal view returns (uint256) {
//         uint random = uint256(
//             keccak256(
//                 abi.encodePacked(
//                     msg.sender,
//                     block.timestamp,
//                     block.coinbase,
//                     gasleft()
//                 )
//             )
//         );
//         return
//             (random > block.number)
//                 ? (random - block.number) % _max
//                 : (block.number - random) % _max;
//     }

//     function supportsInterface(
//         bytes4 interfaceId
//     ) public view override(ERC721, ERC721URIStorage) returns (bool) {
//         return super.supportsInterface(interfaceId);
//     }

//     function safeMint(address to) public returns (uint256) {
//         uint256 tokenId = _nextTokenId++;
//         string memory uriPart = setURI();
//         string memory uri = string(abi.encodePacked(_baseURI(), uriPart));

//         SimpleNft memory nft = SimpleNft(to, tokenId, uri);
//         nfts.push(nft);

//         _safeMint(to, tokenId);
//         _setTokenURI(tokenId, uriPart);
//         return tokenId;
//     }

//     function getOwnerNfts(
//         address _owner
//     ) public view returns (SimpleNft[] memory ownerNft) {
//         uint balance = balanceOf(_owner);
//         ownerNft = new SimpleNft[](balance);
//         for (uint i = 0; i < balance; i++) {
//             uint index = tokenOfOwnerByIndex(_owner, i);
//             ownerNft[i] = nfts[index];
//         }
//     }
// }

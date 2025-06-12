// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.22;

// import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// contract NFTMarketplace is ReentrancyGuard {
//     struct Listing {
//         address seller;
//         uint256 price;
//     }

//     mapping(uint256 => Listing) private _listings;
//     IERC721 private immutable _nftContract;

//     event NFTListed(uint256 indexed tokenId, address seller, uint256 price);
//     event NFTUnlisted(uint256 indexed tokenId, address seller);
//     event PriceUpdated(uint256 indexed tokenId, uint256 newPrice);
//     event NFTPurchased(
//         uint256 indexed tokenId,
//         address buyer,
//         address seller,
//         uint256 price
//     );

//     constructor(address nftAddress) {
//         _nftContract = IERC721(nftAddress);
//     }

//     // 上架NFT需满足所有权和操作授权
//     function listNFT(uint256 tokenId, uint256 price) external {
//         require(_nftContract.ownerOf(tokenId) == msg.sender, "Not token owner");
//         require(price > 0, "Invalid price");
//         require(
//             _nftContract.getApproved(tokenId) == address(this) ||
//                 _nftContract.isApprovedForAll(msg.sender, address(this)),
//             "Contract not approved"
//         );

//         _listings[tokenId] = Listing(msg.sender, price);
//         emit NFTListed(tokenId, msg.sender, price);
//     }

//     // 下架操作原子化处理
//     function unlistNFT(uint256 tokenId) external nonReentrant {
//         Listing memory listing = _listings[tokenId];
//         require(listing.seller == msg.sender, "Not listing owner");

//         delete _listings[tokenId];
//         emit NFTUnlisted(tokenId, msg.sender);
//     }

//     // 价格更新验证所有权
//     function updatePrice(uint256 tokenId, uint256 newPrice) external {
//         require(_listings[tokenId].seller == msg.sender, "Not listing owner");
//         require(newPrice > 0, "Invalid price");

//         _listings[tokenId].price = newPrice;
//         emit PriceUpdated(tokenId, newPrice);
//     }

//     // 购买操作防重入保护
//     function purchaseNFT(uint256 tokenId) external payable nonReentrant {
//         Listing memory listing = _listings[tokenId];
//         require(listing.price > 0, "Not for sale");
//         require(msg.value >= listing.price, "Insufficient funds");

//         delete _listings[tokenId];
//         (bool sent, ) = payable(listing.seller).call{value: msg.value}("");
//         require(sent, "Payment failed");

//         _nftContract.safeTransferFrom(listing.seller, msg.sender, tokenId);
//         emit NFTPurchased(tokenId, msg.sender, listing.seller, listing.price);
//     }

//     // 查询接口
//     function getListing(
//         uint256 tokenId
//     ) external view returns (Listing memory) {
//         return _listings[tokenId];
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
    }

    IERC721 public immutable nft;
    mapping(uint256 => Listing) private listings;

    event NFTListed(uint256 indexed tokenId, address seller, uint256 price);
    event NFTUnlisted(uint256 indexed tokenId);
    event PriceUpdated(uint256 indexed tokenId, uint256 newPrice);
    event NFTPurchased(
        uint256 indexed tokenId,
        address buyer,
        address seller,
        uint256 price
    );

    constructor(address nftAddress) {
        nft = IERC721(nftAddress);
    }

    modifier onlyOwner(uint256 tokenId) {
        require(nft.ownerOf(tokenId) == msg.sender, "Not token owner");
        _;
    }

    modifier listed(uint256 tokenId) {
        require(listings[tokenId].price > 0, "Not listed");
        _;
    }

    function listNFT(
        uint256 tokenId,
        uint256 price
    ) external onlyOwner(tokenId) {
        require(price > 0, "Price must be > 0");
        require(
            nft.getApproved(tokenId) == address(this) ||
                nft.isApprovedForAll(msg.sender, address(this)),
            "Not approved"
        );
        listings[tokenId] = Listing(msg.sender, price);
        emit NFTListed(tokenId, msg.sender, price);
    }

    function unlistNFT(
        uint256 tokenId
    ) external listed(tokenId) onlyOwner(tokenId) {
        delete listings[tokenId];
        emit NFTUnlisted(tokenId);
    }

    function updatePrice(
        uint256 tokenId,
        uint256 newPrice
    ) external listed(tokenId) onlyOwner(tokenId) {
        require(newPrice > 0, "Invalid price");
        listings[tokenId].price = newPrice;
        emit PriceUpdated(tokenId, newPrice);
    }

    function purchaseNFT(
        uint256 tokenId
    ) external payable listed(tokenId) nonReentrant {
        Listing memory listing = listings[tokenId];
        require(msg.value >= listing.price, "Insufficient ETH");

        delete listings[tokenId];

        (bool success, ) = payable(listing.seller).call{value: msg.value}("");
        require(success, "Payment failed");

        nft.safeTransferFrom(listing.seller, msg.sender, tokenId);
        emit NFTPurchased(tokenId, msg.sender, listing.seller, listing.price);
    }

    function getListing(
        uint256 tokenId
    ) external view returns (Listing memory) {
        return listings[tokenId];
    }

    function isListed(uint256 tokenId) external view returns (bool) {
        return listings[tokenId].price > 0;
    }

    function getAllListings()
        external
        view
        returns (uint256[] memory ids, Listing[] memory activeListings)
    {
        uint total = 0;
        for (uint i = 0; i < 10000; i++) {
            if (listings[i].price > 0) total++;
        }

        ids = new uint256[](total);
        activeListings = new Listing[](total);

        uint index = 0;
        for (uint i = 0; i < 10000; i++) {
            if (listings[i].price > 0) {
                ids[index] = i;
                activeListings[index] = listings[i];
                index++;
            }
        }
    }
}

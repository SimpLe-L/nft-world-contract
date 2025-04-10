// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(uint256 => Listing) private _listings;
    IERC721 private immutable _nftContract;

    event NFTListed(uint256 indexed tokenId, address seller, uint256 price);
    event NFTUnlisted(uint256 indexed tokenId, address seller);
    event PriceUpdated(uint256 indexed tokenId, uint256 newPrice);
    event NFTPurchased(
        uint256 indexed tokenId,
        address buyer,
        address seller,
        uint256 price
    );

    constructor(address nftAddress) {
        _nftContract = IERC721(nftAddress);
    }

    // 上架NFT需满足所有权和操作授权
    function listNFT(uint256 tokenId, uint256 price) external {
        require(_nftContract.ownerOf(tokenId) == msg.sender, "Not token owner");
        require(price > 0, "Invalid price");
        require(
            _nftContract.getApproved(tokenId) == address(this) ||
                _nftContract.isApprovedForAll(msg.sender, address(this)),
            "Contract not approved"
        );

        _listings[tokenId] = Listing(msg.sender, price);
        emit NFTListed(tokenId, msg.sender, price);
    }

    // 下架操作原子化处理
    function unlistNFT(uint256 tokenId) external nonReentrant {
        Listing memory listing = _listings[tokenId];
        require(listing.seller == msg.sender, "Not listing owner");

        delete _listings[tokenId];
        emit NFTUnlisted(tokenId, msg.sender);
    }

    // 价格更新验证所有权
    function updatePrice(uint256 tokenId, uint256 newPrice) external {
        require(_listings[tokenId].seller == msg.sender, "Not listing owner");
        require(newPrice > 0, "Invalid price");

        _listings[tokenId].price = newPrice;
        emit PriceUpdated(tokenId, newPrice);
    }

    // 购买操作防重入保护
    function purchaseNFT(uint256 tokenId) external payable nonReentrant {
        Listing memory listing = _listings[tokenId];
        require(listing.price > 0, "Not for sale");
        require(msg.value >= listing.price, "Insufficient funds");

        delete _listings[tokenId];
        (bool sent, ) = payable(listing.seller).call{value: msg.value}("");
        require(sent, "Payment failed");

        _nftContract.safeTransferFrom(listing.seller, msg.sender, tokenId);
        emit NFTPurchased(tokenId, msg.sender, listing.seller, listing.price);
    }

    // 查询接口
    function getListing(
        uint256 tokenId
    ) external view returns (Listing memory) {
        return _listings[tokenId];
    }
}

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

    uint256[] private listedTokenIds;
    mapping(uint256 => uint256) private listedTokenIndex;

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

        if (listings[tokenId].price == 0) {
            listedTokenIndex[tokenId] = listedTokenIds.length;
            listedTokenIds.push(tokenId);
        }

        listings[tokenId] = Listing(msg.sender, price);
        emit NFTListed(tokenId, msg.sender, price);
    }

    function unlistNFT(
        uint256 tokenId
    ) external listed(tokenId) onlyOwner(tokenId) {
        delete listings[tokenId];

        _removeTokenId(tokenId);

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
        _removeTokenId(tokenId);

        (bool sent, ) = payable(listing.seller).call{value: listing.price}("");
        require(sent, "Payment failed");

        if (msg.value > listing.price) {
            (bool refundOk, ) = payable(msg.sender).call{
                value: msg.value - listing.price
            }("");
            require(refundOk, "Refund failed");
        }

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
        uint256 total = listedTokenIds.length;
        ids = new uint256[](total);
        activeListings = new Listing[](total);

        for (uint i = 0; i < total; i++) {
            uint256 tokenId = listedTokenIds[i];
            ids[i] = tokenId;
            activeListings[i] = listings[tokenId];
        }
    }

    function _removeTokenId(uint256 tokenId) internal {
        uint256 lastTokenId = listedTokenIds[listedTokenIds.length - 1];
        uint256 index = listedTokenIndex[tokenId];

        if (tokenId != lastTokenId) {
            listedTokenIds[index] = lastTokenId;
            listedTokenIndex[lastTokenId] = index;
        }

        listedTokenIds.pop();
        delete listedTokenIndex[tokenId];
    }
}

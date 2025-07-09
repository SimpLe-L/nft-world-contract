// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/MarketPlace.sol";

contract DeployMarket is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // 从环境变量中读取 NFT 合约地址
        address nftAddress = vm.envAddress("NFT_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);
        NFTMarketplace market = new NFTMarketplace(nftAddress);
        console2.log("market deployed at:", address(market));
        vm.stopBroadcast();
    }
}

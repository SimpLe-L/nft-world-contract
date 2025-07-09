// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "../src/Nft.sol";

contract DeployMyNft is Script {
    function run() external {
        // 获取部署地址私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        MyNft nft = new MyNft();
        console2.log("MyNft deployed at:", address(nft));
        vm.stopBroadcast();
    }
}

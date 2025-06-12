// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/ERC20.sol";

contract DeployCounterScript is Script {
    function run() external returns (SimpleToken) {
        // vm.envUint("PRIVATE_KEY") 从环境变量读取私钥
        // vm.envString("PRIVATE_KEY_STRING") 也可以，然后转换为 uint256
        // 为了简单起见，我们也可以直接使用Anvil提供的第一个私钥 (不推荐用于生产环境)
        // uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        // 更推荐的方式是从环境变量中获取私钥
        // 你可以在运行脚本时通过 PRIVATE_KEY=0x... forge script ... 的方式传入
        // 或者在 .env 文件中设置 (需要配合 forge-std/DotEnv.sol)
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            // 如果环境变量没有设置，使用 Anvil 第一个默认账户的私钥
            deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
            console.log(
                "Warning: PRIVATE_KEY environment variable not set. Using default Anvil private key 0."
            );
        }

        vm.startBroadcast(deployerPrivateKey);
        SimpleToken st = new SimpleToken(address(0), 100000000); // 部署合约

        vm.stopBroadcast();

        console.log("Counter contract deployed to:", address(st));
        console.log("Deployer address:", vm.addr(deployerPrivateKey));

        return st; // 返回部署的合约实例
    }
}

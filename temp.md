## 部署

nft:
forge script script/nft.s.sol:DeployMyNft --rpc-url http://127.0.0.1:8545 --broadcast -vvvv

market:
forge script script/market.s.sol:DeployMarket --rpc-url http://127.0.0.1:8545 --broadcast -vvvv


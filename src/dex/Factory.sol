// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

import "./interfaces/IFactory.sol";
import "./Pool.sol";

contract Factory is IFactory {
    mapping(address => mapping(address => address[])) public pools;

    Parameters public override parameters;

    // 保证交易对顺序一致
    function sortToken(
        address tokenA,
        address tokenB
    ) private pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function getPool(
        address tokenA,
        address tokenB,
        uint32 index
    ) external view override returns (address) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        require(tokenA != address(0) && tokenB != address(0), "ZERO_ADDRESS");

        // Declare token0 and token1
        address token0;
        address token1;

        (token0, token1) = sortToken(tokenA, tokenB);

        return pools[token0][token1][index];
    }

    function createPool(
        address tokenA,
        address tokenB,
        int24 tickLower, // 区间下限
        int24 tickUpper, // 区间上限
        uint24 fee
    ) external override returns (address pool) {
        // validate token's individuality
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");

        // Declare token0 and token1
        address token0;
        address token1;

        // sort token, avoid the mistake of the order
        (token0, token1) = sortToken(tokenA, tokenB);

        // get current all pools
        address[] memory existingPools = pools[token0][token1];

        // check if the pool already exists
        for (uint256 i = 0; i < existingPools.length; i++) {
            IPool currentPool = IPool(existingPools[i]);

            if (
                currentPool.tickLower() == tickLower &&
                currentPool.tickUpper() == tickUpper &&
                currentPool.fee() == fee
            ) {
                return existingPools[i];
            }
        }

        // save pool info
        // 在创建 Pool 合约之前，Factory 合约将参数存储在 parameters 变量中。然后使用 CREATE2 操作码创建 Pool 合约实例。
        parameters = Parameters(
            address(this),
            token0,
            token1,
            tickLower,
            tickUpper,
            fee
        );

        // generate create2 salt
        bytes32 salt = keccak256(
            abi.encode(token0, token1, tickLower, tickUpper, fee)
        );

        // create pool, 通过token0和token1, tickLower和tickUpper, fee生成可预测的地址
        // CREATE2 是以太坊虚拟机 (EVM) 中的一种操作码，用于创建新的合约。与 CREATE 操作码不同，CREATE2 允许在合约创建之前预测其地址。CREATE2 使用合约创建者的地址、一个 salt 值和合约的字节码来计算新合约的地址。
        pool = address(new Pool{salt: salt}());

        // save created pool
        // 举例： pools[sui][usdc] = [0x123..., 0x456..., 0x789...] 是一个地址数组，包含了多个池的地址。每个地址代表一个 Pool 合约实例。
        pools[token0][token1].push(pool);

        // delete pool info
        delete parameters;

        emit PoolCreated(
            token0,
            token1,
            uint32(existingPools.length),
            tickLower,
            tickUpper,
            fee,
            pool
        );
    }
}

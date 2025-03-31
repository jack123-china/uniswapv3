/*
管理器合约将这样工作：
为了铸造流动性，我们将批准管理器合约花费代币。
然后我们将调用管理器合约的 mint 函数，并传递铸造参数，以及我们想要提供流动性的池子地址。
管理器合约将调用池子的 mint 函数并实现 uniswapV3MintCallback。它将有权限将我们的代币发送到池子合约。
为了交换代币，我们也将批准管理器合约花费代币。
然后我们将调用管理器合约的 swap 函数，类似于铸造，它将把调用传递给池子。 管理器合约将把我们的代币发送到池子合约，池子合约将交换它们并将输出金额发送给我们。
 */

pragma solidity ^0.8.14;

import "../src/UniswapV3Pool.sol";
import "../src/interfaces/IERC20.sol";

contract UniswapManager {
    function mint(
        address poolAddress_,
        int24 lowerTick,
        int24 upperTick,
        uint128 liquidity,
        bytes calldata data
    ) public returns (uint256, uint256) {
        return
            UniswapV3Pool(poolAddress_).mint(
                msg.sender,
                lowerTick,
                upperTick,
                liquidity,
                data
            );
    }

    function swap(
        address poolAddress_,
        bytes calldata data
    ) public returns (int256, int256) {
        return UniswapV3Pool(poolAddress_).swap(msg.sender, data);
    }

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        UniswapV3Pool.CallBackData memory extra = abi.decode(
            data,
            (UniswapV3Pool.CallBackData)
        );
        IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
        IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
    }

    function uniswapV3SwapCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        UniswapV3Pool.CallBackData memory extra = abi.decode(
            data,
            (UniswapV3Pool.CallBackData)
        );

        if (amount0 > 0) {
            IERC20(extra.token0).transferFrom(
                extra.payer,
                msg.sender,
                uint256(amount0)
            );
        }

        if (amount1 > 0) {
            IERC20(extra.token1).transferFrom(
                extra.payer,
                msg.sender,
                uint256(amount1)
            );
        }
    }
}

pragma solidity ^0.8.14;

import "./lib/Position.sol";
import "./lib/Tick.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV3MintCallback.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";

//两个代币地址
//存储流动性头寸  唯一的头寸标识符，值是存储头寸信息的结构体。
// tick 注册表   键是 tick 索引，值是存储 tick 信息的结构体
//tick 范围 将限制存储为常量
// 存储流动性数量 L
//Slot0  跟踪当前价格和相关的 tick
contract UniswapV3Pool {
    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    error InvalidTickRange();
    error ZeroLiuqidity();
    error InsufficientInputAmount();

    struct Slot0 {
        //current sqrt(P)
        uint160 sqrtPriceX96; //当前价格
        //current tick
        int24 tick;  //相关的tick
    }

    struct CallBackData {
        address token0;
        address token1;
        address payer;
    }

    Slot0 public slot0;

    address public immutable token0;
    address public immutable token1;

    int24 internal constant MIN_TICK = -887272; //todo:这个为什么定义这个值
    int24 internal constant MAX_TICK = -MIN_TICK;

    uint128 public liquidity;

    //tick info
    mapping(int24 => Tick.Info) public ticks;
    //positions info 头寸信息
    mapping(bytes32 => Position.Info) public positions;

    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    constructor(
        address token0_,
        address token1_,
        uint160 sqrtPriceX96,
        int24 tick
    ) {
        token0 = token0_;
        token1 = token1_;

        slot0 = Slot0({sqrtPriceX96: sqrtPriceX96, tick: tick});
    }

    // 参数 所有者地址，用于跟踪流动性的所有者
    //      上限和下限 tick
    //      提供的流动性数量（在辅助合约中将代币数量转换为L）
    function mint(
        address owner,
        int24 lowertick,
        int24 uppertick,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1) {
        if (
            lowertick >= uppertick ||
            lowertick < MIN_TICK ||
            uppertick > MAX_TICK
        ) revert InvalidTickRange();

        if (amount == 0) revert ZeroLiuqidity();

        //添加一个 tick 和一个头寸
        ticks.update(lowertick, amount);
        ticks.update(uppertick, amount);

        Position.Info storage position = positions.get(
            owner,
            lowertick,
            uppertick
        );
        position.update(amount);

        //添加x y的数量 
        amount0 = 0.998976618347425280 ether; // TODO: replace with calculation  
        amount1 = 5000 ether; // TODO: replace with calculation

        liquidity += uint128(amount);

        uint256 balance0Before;
        uint256 balance1Before;

        if (amount0 > 0) balance0Before = balance0();
        if (amount1 > 0) balance1Before = balance1();
        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(
            amount0,
            amount1,
            data
        );
        if (amount0 > 0 && balance0Before + amount0 > balance0())
            revert InsufficientInputAmount();
        if (amount1 > 0 && balance1Before + amount1 > balance1())
            revert InsufficientInputAmount();

        emit Mint(
            msg.sender,
            owner,
            lowertick,
            uppertick,
            amount,
            amount0,
            amount1
        );
    }

    function swap(
        address recipient,
        bytes calldata data
    ) public returns (int256 amount0, int256 amount1) {
        int24 nextTick = 85184;
        uint160 nextPrice = 5604469350942327889444743441197;

        amount0 = -0.008396714242162444 ether;
        amount1 = 42 ether;

        (slot0.tick, slot0.sqrtPriceX96) = (nextTick, nextPrice);

        IERC20(token0).transfer(recipient, uint256(-amount0));
        uint256 balance1Before = balance1();
        IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
            amount0,
            amount1,
            data
        );
        if (balance1Before + uint256(amount1) < balance1())
            revert InsufficientInputAmount();

        emit Swap(
            msg.sender,
            recipient,
            amount0,
            amount1,
            slot0.sqrtPriceX96,
            liquidity,
            slot0.tick
        );
    }

    //internal
    function balance0() internal returns (uint256 balance) {
        balance = IERC20(token0).balanceOf(address(this));
    }

    function balance1() internal returns (uint256 balance) {
        balance = IERC20(token1).balanceOf(address(this));
    }
}

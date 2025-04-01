pragma solidity ^0.8.14;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "../src/UniswapV3Pool.sol";
import "../src/UniswapV3Manager.sol";
import "../test/ERC20Mintable.sol";

contract DeployDevelopment is Script {
    function run() public {
        uint256 wethBalance = 1 ether;
        uint256 usdcBalance = 5042 ether;

        int24 currentTick = 85176;
        uint160 currentSqrtP = 5602277097478614198912276234240;

        //在 broadcast() 作弊码之后或 startBroadcast()/stopBroadcast() 之间的所有内容都会被转换为交易，这些交易会被发送到执行脚本的节点。
        vm.startBroadcast();
        ERC20Mintable token0 = new ERC20Mintable("wrapped Ether", "WETH", 18);
        ERC20Mintable token1 = new ERC20Mintable("usdc coin", "USDC", 18);

        UniswapV3Pool pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            currentSqrtP,
            currentTick
        );

        UniswapManager manager = new UniswapManager();

        token0.mint(msg.sender, wethBalance);
        token0.mint(msg.sender, usdcBalance);

        vm.stopBroadcast();

        console.log("WETH address", address(token0));
        console.log("USDC address", address(token1));
        console.log("Pool address", address(pool));
        console.log("Manager address", address(manager));
    }
}

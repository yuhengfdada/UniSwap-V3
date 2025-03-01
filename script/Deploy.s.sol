// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Token.sol";
import "../src/UniswapV3Pool.sol";
import "../src/UniswapV3Manager.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy test tokens
        Token weth = new Token("Wrapped Ether", "WETH", 0);
        Token usdc = new Token("USD Coin", "USDC", 0);

        // Initial price parameters
        uint160 initSqrtPriceX96 = 5602277097478614198912276234240;
        int24 initTick = 85176;

        // Deploy Pool and Manager
        UniswapV3Pool pool = new UniswapV3Pool(address(weth), address(usdc), initSqrtPriceX96, initTick);
        UniswapV3Manager manager = new UniswapV3Manager();

        // Mint initial token supplies with new amounts
        weth.mint(msg.sender, 1 ether);
        usdc.mint(msg.sender, 5042 ether);

        // Log deployed contracts
        console.log("WETH deployed to:", address(weth));
        console.log("USDC deployed to:", address(usdc));
        console.log("Pool deployed to:", address(pool));
        console.log("Manager deployed to:", address(manager));

        vm.stopBroadcast();
    }
}

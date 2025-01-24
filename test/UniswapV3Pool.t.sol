// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UniswapV3Pool} from "../src/UniswapV3Pool.sol";
import {Token} from "../src/Token.sol";
import {IUniswapV3MintCallback} from "../src/interfaces/IUniswapV3MintCallback.sol";

contract MintCaller is IUniswapV3MintCallback {
    address token0;
    address token1;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }

    function uniswapV3MintCallback(uint256 amount0, uint256 amount1) external override {
        console.log("MintCallback: amount0: %d, amount1: %d", amount0, amount1);
        IERC20(token0).transfer(msg.sender, amount0);
        IERC20(token1).transfer(msg.sender, amount1);
    }
}

contract TestUniswapV3Pool is Test {
    struct TestCaseParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        uint160 currentSqrtP;
        int24 currentTick;
        int24 lowerTick;
        int24 upperTick;
        uint128 liquidity;
        bool mintLiqudity;
        bool shouldTransferInCallback;
    }

    Token token0;
    Token token1;
    UniswapV3Pool pool;

    function setUp() public {
        token0 = new Token("TokenX", "X", 0);
        token1 = new Token("TokenY", "Y", 0);
    }

    function setupTestCase(TestCaseParams memory params) internal {
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        pool = new UniswapV3Pool(address(token0), address(token1), params.currentSqrtP, params.currentTick);
    }

    function testMint() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentTick: 85176,
            lowerTick: 84222,
            upperTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            mintLiqudity: true
        });

        setupTestCase(params);

        MintCaller mintCaller = new MintCaller(address(token0), address(token1));
        address mintCallerAddr = address(mintCaller);

        token0.mint(mintCallerAddr, params.wethBalance);
        token1.mint(mintCallerAddr, params.usdcBalance);

        vm.prank(mintCallerAddr);
        (uint256 poolBalance0, uint256 poolBalance1) =
            pool.mint(mintCallerAddr, params.lowerTick, params.upperTick, params.liquidity);

        uint256 expectedAmount0 = 0.99897661834742528 ether;
        uint256 expectedAmount1 = 5000 ether;

        assertEq(poolBalance0, expectedAmount0);
        assertEq(poolBalance1, expectedAmount1);
        assertEq(token0.balanceOf(address(pool)), expectedAmount0);
        assertEq(token1.balanceOf(address(pool)), expectedAmount1);
    }
}

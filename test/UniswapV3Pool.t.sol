// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UniswapV3Pool} from "../src/UniswapV3Pool.sol";
import {Token} from "../src/Token.sol";
import {IUniswapV3MintCallback} from "../src/interfaces/IUniswapV3MintCallback.sol";
import {IUniswapV3SwapCallback} from "../src/interfaces/IUniswapV3SwapCallback.sol";

contract TestUniswapV3Pool is Test, IUniswapV3MintCallback, IUniswapV3SwapCallback {
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
    address token0Addr;
    address token1Addr;
    UniswapV3Pool pool;

    function setUp() public {
        token0 = new Token("TokenX", "X", 0);
        token1 = new Token("TokenY", "Y", 0);
        token0Addr = address(token0);
        token1Addr = address(token1);
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

        address mintCallerAddr = address(1);

        token0.mint(mintCallerAddr, params.wethBalance);
        token1.mint(mintCallerAddr, params.usdcBalance);

        address managerAddr = address(this);
        vm.prank(mintCallerAddr);
        token0.approve(managerAddr, params.wethBalance);
        vm.prank(mintCallerAddr);
        token1.approve(managerAddr, params.usdcBalance);

        (uint256 poolBalance0, uint256 poolBalance1) = pool.mint(
            mintCallerAddr,
            params.lowerTick,
            params.upperTick,
            params.liquidity,
            abi.encode(UniswapV3Pool.CallbackData(token0Addr, token1Addr, mintCallerAddr))
        );

        uint256 expectedAmount0 = 0.99897661834742528 ether;
        uint256 expectedAmount1 = 5000 ether;

        assertEq(poolBalance0, expectedAmount0);
        assertEq(poolBalance1, expectedAmount1);
        assertEq(token0.balanceOf(address(pool)), expectedAmount0);
        assertEq(token1.balanceOf(address(pool)), expectedAmount1);
    }

    function testSwapBuyEth() public {
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
        setupTestCaseThenMint(params);

        address swapCallerAddr = address(1);

        token1.mint(swapCallerAddr, 42 ether);

        address managerAddr = address(this);

        vm.prank(swapCallerAddr);
        token1.approve(managerAddr, 42 ether);

        pool.swap(swapCallerAddr, abi.encode(UniswapV3Pool.CallbackData(token0Addr, token1Addr, swapCallerAddr)));

        assertEq(token1.balanceOf(swapCallerAddr), 0);
        assertEq(token0.balanceOf(swapCallerAddr), 0.008396714242162444 ether);

        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        assertEq(sqrtPriceX96, 5604469350942327889444743441197, "invalid current sqrtP");
        assertEq(tick, 85184, "invalid current tick");
        assertEq(pool.liquidity(), 1517882343751509868544, "invalid current liquidity");
    }

    /**
     * UTILITY FUNCTIONS **
     */
    function setupTestCase(TestCaseParams memory params) internal {
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        pool = new UniswapV3Pool(address(token0), address(token1), params.currentSqrtP, params.currentTick);
    }

    function setupTestCaseThenMint(TestCaseParams memory params) internal {
        setupTestCase(params);
        token0.approve(address(this), params.wethBalance);
        token1.approve(address(this), params.usdcBalance);

        (uint256 poolBalance0, uint256 poolBalance1) = pool.mint(
            address(this),
            params.lowerTick,
            params.upperTick,
            params.liquidity,
            abi.encode(UniswapV3Pool.CallbackData(token0Addr, token1Addr, address(this)))
        );
    }

    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) external override {
        console.log("MintCallback: amount0: %d, amount1: %d", amount0, amount1);
        UniswapV3Pool.CallbackData memory callbackData = abi.decode(data, (UniswapV3Pool.CallbackData));
        IERC20(callbackData.token0).transferFrom(callbackData.payer, msg.sender, amount0);
        IERC20(callbackData.token1).transferFrom(callbackData.payer, msg.sender, amount1);
    }

    function uniswapV3SwapCallback(int256 amount0, int256 amount1, bytes calldata data) external override {
        console.log("SwapCallback");
        console.logInt(amount0);
        console.logInt(amount1);
        UniswapV3Pool.CallbackData memory callbackData = abi.decode(data, (UniswapV3Pool.CallbackData));

        if (amount0 > 0) IERC20(callbackData.token0).transferFrom(callbackData.payer, msg.sender, uint256(amount0));
        if (amount1 > 0) IERC20(callbackData.token1).transferFrom(callbackData.payer, msg.sender, uint256(amount1));
    }
}

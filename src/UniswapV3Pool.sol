// SPDX-License-Identifier: MIT

import {Tick} from "./libs/Tick.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Position} from "./libs/Position.sol";
import {IUniswapV3MintCallback} from "./interfaces/IUniswapV3MintCallback.sol";

contract UniswapV3Pool {
    error InsufficientInputAmount();

    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;
    using Tick for mapping(int24 => Tick.Info);

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    // Current price and tick
    struct Slot0 {
        uint160 sqrtPriceX96; // Q96.64 Number
        int24 tick;
    }

    Slot0 public slot0;

    // Pool tokens, immutable
    address public immutable token0;
    address public immutable token1;

    mapping(int24 => Tick.Info) ticks;
    // bytes32 combines (owner address, lower tick, upper tick)
    mapping(bytes32 => Position.Info) positions;

    uint128 totalLiquidity;

    constructor(address _token0, address _token1, uint160 _sqrtPriceX96, int24 _tick) {
        token0 = _token0;
        token1 = _token1;
        slot0 = Slot0({sqrtPriceX96: _sqrtPriceX96, tick: _tick});
    }

    function mint(address owner, int24 lowerTick, int24 upperTick, uint128 amount)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        // update states
        Position.Info storage position = positions.get(owner, lowerTick, upperTick);
        position.update(amount);
        ticks.update(lowerTick, upperTick, amount);
        totalLiquidity += uint128(amount);

        // calc delta x, delta y
        (amount0, amount1) = calculateLiquidity(lowerTick, upperTick, amount);

        // callback to collect tokens
        (uint256 balance0Before, uint256 balance1Before) = (balance0(), balance1());
        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1);

        require(balance0Before + amount0 <= balance0(), "M0");
        require(balance1Before + amount1 <= balance1(), "M1");

        // emit Mint(...)
    }

    function balance0() internal returns (uint256 balance) {
        balance = IERC20(token0).balanceOf(address(this));
    }

    function balance1() internal returns (uint256 balance) {
        balance = IERC20(token1).balanceOf(address(this));
    }
}

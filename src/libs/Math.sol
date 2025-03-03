// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./FixedPoint96.sol";
import "prb-math/contracts/PRBMath.sol";

library Math {
    function calcAmount0Delta(uint160 sqrtPriceAX96, uint160 sqrtPriceBX96, uint128 liquidity, bool roundUp)
        internal
        pure
        returns (uint256 amount0)
    {
        if (sqrtPriceAX96 > sqrtPriceBX96) {
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
        }

        // liquidity needs to be multiplied by Q96 since it needs to mult by Q64.96, then divided by Q64.96 twice.
        uint256 adjustedLiquidity = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 priceDiff = sqrtPriceBX96 - sqrtPriceAX96;
        if (roundUp) {
            amount0 = divRoundUp(mulDivRoundUp(adjustedLiquidity, priceDiff, sqrtPriceAX96), sqrtPriceBX96);
        } else {
            amount0 = PRBMath.mulDiv(adjustedLiquidity, priceDiff, sqrtPriceBX96) / sqrtPriceAX96;
        }
    }

    function calcAmount1Delta(uint160 sqrtPriceAX96, uint160 sqrtPriceBX96, uint128 liquidity, bool roundUp)
        internal
        pure
        returns (uint256 amount1)
    {
        if (sqrtPriceAX96 > sqrtPriceBX96) {
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
        }

        // here, liquidity needs to be divided by Q96 since it needs to mult by Q64.96 once.
        if (roundUp) {
            amount1 = mulDivRoundUp(liquidity, sqrtPriceBX96 - sqrtPriceAX96, FixedPoint96.Q96);
        } else {
            amount1 = PRBMath.mulDiv(liquidity, sqrtPriceBX96 - sqrtPriceAX96, FixedPoint96.Q96);
        }
    }

    function mulDivRoundUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    function divRoundUp(uint256 numerator, uint256 denominator) internal pure returns (uint256 result) {
        assembly {
            result := add(div(numerator, denominator), gt(mod(numerator, denominator), 0))
        }
    }
}

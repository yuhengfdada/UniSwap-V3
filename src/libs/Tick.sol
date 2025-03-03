// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

library Tick {
    struct Info {
        bool initialized;
        uint128 liquidity;
    }

    function update(mapping(int24 => Tick.Info) storage self, int24 tick, uint128 amount)
        public
        returns (bool flipped)
    {
        Tick.Info storage info = self[tick];
        uint128 liquidityBefore = info.liquidity;

        if (info.liquidity == 0) {
            info.initialized = true;
        }
        info.liquidity += amount;

        uint128 liquidityAfter = info.liquidity;

        return (liquidityBefore == 0) != (liquidityAfter == 0);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

library Tick {
    struct Info {
        bool initialized;
        uint128 liquidity;
    }

    // room for gas optimization
    function update(mapping(int24 => Tick.Info) storage self, int24 tick, uint128 amount) public {
        Tick.Info storage info = self[tick];

        if (info.liquidity == 0) {
            info.initialized = true;
        }
        info.liquidity += amount;
    }
}

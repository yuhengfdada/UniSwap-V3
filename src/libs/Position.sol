// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

library Position {
    struct Info {
        uint128 liquidity;
    }

    function get(mapping(bytes32 => Position.Info) storage self, address owner, int24 lowerTick, int24 upperTick)
        public
        view
        returns (Position.Info storage)
    {
        return self[keccak256(abi.encodePacked(owner, lowerTick, upperTick))];
    }

    // room for gas optimization
    function update(Position.Info storage self, uint128 amount) public {
        self.liquidity += amount;
    }
}

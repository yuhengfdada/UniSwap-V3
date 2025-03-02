// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

import {BitMath} from "./BitMath.sol";

library TickBitmap {
    function position(int24 tick) internal pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick % 256));
    }

    // function tickFromPosition(int16 wordPos, uint8 bitPos) internal pure returns (int24 tick) {
    //     tick = ((int24(wordPos) << 8) | int24(uint24(bitPos)));
    // }

    function flipTick(mapping(int16 => uint256) storage self, int24 tick, int24 tickSpacing) internal {
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        uint256 mask = 1 << bitPos; // within a word, bitPos increases from right to left
        self[wordPos] ^= mask;
    }

    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool sellingX
    ) internal view returns (int24 nextTick, bool initialized) {
        int24 compressedTick = tick / tickSpacing;
        if (sellingX) {
            // selling X, find to the right within current word (since price will decrease)
            (int16 wordPos, uint8 bitPos) = position(compressedTick);
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;
            initialized = masked != 0;

            // BitMath.mostSignificantBit(masked): the bitPos of the target tick
            // bitPos is essentially tick % 256. So, bitPos - BitMath.mostSignificantBit(masked) is the distance between compressedTick and the target tick.
            nextTick = initialized
                ? (compressedTick - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                : (compressedTick - int24(uint24(bitPos))) * tickSpacing; // finding the next word to the left
        } else {
            // buying X, find to the left within current word (since price will increase)
            (int16 wordPos, uint8 bitPos) = position(compressedTick + 1); // price increasing so +1
            uint256 mask = ~((1 << bitPos) - 1); // we already had +1 so no need to add it here
            uint256 masked = self[wordPos] & mask;
            initialized = masked != 0;

            nextTick = initialized
                ? (compressedTick + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                : (compressedTick + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing; // finding the next word to the right
        }
    }
}

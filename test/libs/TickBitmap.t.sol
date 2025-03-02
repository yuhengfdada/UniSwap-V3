// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "../../src/libs/TickBitmap.sol";

contract TickBitmapTest is Test {
    using TickBitmap for mapping(int16 => uint256);

    mapping(int16 => uint256) bitmap;

    function testFlipTick() public {
        (int16 wordPos, uint8 bitPos) = TickBitmap.position(1);
        assertEq(wordPos, 0);
        assertEq(bitPos, 1);

        bitmap.flipTick(1, 1);
        assertTrue(bitmap[0] == 2); // 2 is binary 10, representing tick 1 is set

        bitmap.flipTick(1, 1);
        assertTrue(bitmap[0] == 0); // Should be back to 0 after second flip
    }

    function testPosition() public pure {
        (int16 wordPos, uint8 bitPos) = TickBitmap.position(1);
        assertEq(wordPos, 0);
        assertEq(bitPos, 1);

        (wordPos, bitPos) = TickBitmap.position(-1);
        assertEq(wordPos, -1);
        assertEq(bitPos, 255);

        (wordPos, bitPos) = TickBitmap.position(256);
        assertEq(wordPos, 1);
        assertEq(bitPos, 0);
    }

    function testNextInitializedTick() public {
        // Set some ticks as initialized
        bitmap.flipTick(2, 1);
        bitmap.flipTick(8, 1);
        bitmap.flipTick(16, 1);

        // Test finding larger tick
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(1, 1, false);
        assertEq(next, 2);
        assertTrue(initialized);

        (next, initialized) = bitmap.nextInitializedTickWithinOneWord(2, 1, false);
        assertEq(next, 8);
        assertTrue(initialized);

        (next, initialized) = bitmap.nextInitializedTickWithinOneWord(3, 1, false);
        assertEq(next, 8);
        assertTrue(initialized);

        // Test finding smaller & equal tick
        (next, initialized) = bitmap.nextInitializedTickWithinOneWord(9, 1, true);
        assertEq(next, 8);
        assertTrue(initialized);

        (next, initialized) = bitmap.nextInitializedTickWithinOneWord(2, 1, true);
        assertEq(next, 2);
        assertTrue(initialized);
    }
}

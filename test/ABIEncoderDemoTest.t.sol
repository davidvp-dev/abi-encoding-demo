// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import {Test} from "forge-std/Test.sol";
import {ABIEncoderDemo} from "../src/ABIEncoderDemo.sol";

/**
 * @title ABIEncoderDemoTest
 * @author David Villalgordo
 * @notice Comprehensive tests targeting 100% coverage for ABIEncoderDemo
 */
contract ABIEncoderDemoTest is Test {
    ABIEncoderDemo private demo;

    /// @notice Deploys a fresh ABIEncoderDemo instance before each test.
    function setUp() public {
        demo = new ABIEncoderDemo();
    }

    /// @notice Verifies that a pool identifier is independent of token ordering.
    function test_createPoolId_sameForBothTokenOrders_OK() public view {
        address tokenA = address(0x1000);
        address tokenB = address(0x2000);
        uint24 fee = 3000;

        bytes32 idAB = demo.createPoolIdentifier(tokenA, tokenB, fee);
        bytes32 idBA = demo.createPoolIdentifier(tokenB, tokenA, fee);

        assertEq(idAB, idBA);
    }

    /// @notice Verifies that different fee values produce different pool identifiers.
    function test_createPoolId_differentFeeDifferentId_OK() public view {
        address tokenA = address(0x1000);
        address tokenB = address(0x2000);
        uint24 fee0 = 3000;
        uint24 fee1 = 500;

        bytes32 idLow = demo.createPoolIdentifier(tokenA, tokenB, fee0);
        bytes32 idHigh = demo.createPoolIdentifier(tokenB, tokenA, fee1);

        assertNotEq(idLow, idHigh);
    }

    /// @notice Verifies the encoded trading position data and its hash.
    function test_encodeTradingPosition_returnsExpectedDataAndHash_OK() public {
        address user = makeAddr("alice");
        address tokenIn = address(0x1000);
        address tokenOut = address(0x2000);
        uint256 amountIn = 10e18;
        uint256 amountOut = 20e18;

        // Freeze block timestamp to a known value
        uint256 fixedTs = 1_700_000_000;
        vm.warp(fixedTs);

        (bytes32 positionId, bytes memory encodedData) =
            demo.encodeTradingPosition(user, tokenIn, tokenOut, amountIn, amountOut);

        bytes memory expectedData = abi.encodePacked(user, tokenIn, tokenOut, amountIn, amountOut, fixedTs);
        bytes32 expectedPositionId = keccak256(expectedData);

        assertEq(positionId, expectedPositionId, "encoding trading position mismatch");
        assertEq(encodedData, expectedData, "position id keccak mismatch");
    }

    /// @notice Verifies the encoding of a swap path, amounts, and deadline.
    function test_encodeSwapData_encodesPathAmountsDeadline_OK() public {
        address[] memory path = new address[](2);
        path[0] = vm.addr(1);
        path[1] = vm.addr(2);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        // Freeze block timestamp to a known value
        uint256 deadline = 1_700_000_000;
        vm.warp(deadline);

        // Encode the path
        bytes memory expectedPath;
        for (uint256 i = 0; i < path.length; i++) {
            expectedPath = abi.encodePacked(expectedPath, path[i]);
        }

        // Encode the amounts
        bytes memory expectedAmounts;
        for (uint256 i = 0; i < amounts.length; i++) {
            expectedAmounts = abi.encodePacked(expectedAmounts, amounts[i]);
        }

        bytes memory expectedSwapData = abi.encodePacked(expectedPath, expectedAmounts, deadline);

        (bytes memory swapData) = demo.encodeSwapData(path, amounts, deadline);

        assertEq(swapData, expectedSwapData, "mismatch in encoded data");
    }

    /// @notice Verifies that swap encoding reverts when path and amount lengths differ.
    function test_encodeSwapData_differentArrayLengths_KO() public {
        address[] memory path = new address[](3);
        path[0] = vm.addr(1);
        path[1] = vm.addr(2);
        path[2] = vm.addr(3);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        // Freeze block timestamp to a known value
        uint256 deadline = 1_700_000_000;
        vm.warp(deadline);

        vm.expectRevert("Array length mismatch");
        demo.encodeSwapData(path, amounts, deadline);
    }

    /// @notice Verifies the encoded limit order data and its hash.
    function test_encodeLimitOrder_returnsExpectedOrderHashAndOrderData_OK() public {
        address maker = makeAddr("alice");
        address taker = makeAddr("bob");
        address tokenIn = address(0x001);
        address tokenOut = address(0x002);
        uint256 amountIn = 1 ether;
        uint256 amountOut = 2 ether;
        uint256 nonce = 5;

        (bytes32 orderHash, bytes memory orderData) =
            demo.encodeLimitOrder(maker, taker, tokenIn, tokenOut, amountIn, amountOut, nonce);

        bytes memory expectedOrderData =
            abi.encodePacked(maker, taker, tokenIn, tokenOut, amountIn, amountOut, nonce, "LIMIT_ORDER_V1");
        bytes32 expectedOrderHash = keccak256(expectedOrderData);

        assertEq(orderData, expectedOrderData, "order limit data mismatch");
        assertEq(orderHash, expectedOrderHash, "order hash mismatch");
    }

    /// @notice Verifies the position identifier generated for a yield position.
    function test_encodeYieldPosition_returnsExpectedPositionId_OK() public {
        address user = makeAddr("alice");
        address tokenA = address(0x1000);
        address tokenB = address(0x2000);
        uint256 amount = 1 ether;
        uint256 startTime = block.timestamp + 1_000_000;
        uint24 fee = 3000;

        bytes32 poolId = demo.createPoolIdentifier(tokenA, tokenB, fee);
        bytes32 expectedPositionId = keccak256(abi.encodePacked(user, poolId, amount, startTime, "YIELD_POSITION"));
        bytes32 positionId = demo.encodeYieldPosition(user, poolId, amount, startTime);

        assertEq(positionId, expectedPositionId, "position hashes mismatch");
    }

    /// @notice Verifies the encoded flash loan data.
    function test_encodeFlashLoanData_returnsExpectedFlashData_OK() public view {
        address token = address(0x1000);
        uint256 amount = 1 ether;
        bytes memory callbackData = "123";

        bytes memory flashData = demo.encodeFlashLoanData(token, amount, callbackData);
        bytes memory expectedFlashData = abi.encodePacked(token, amount, callbackData, "FLASH_LOAN_V1");

        assertEq(flashData, expectedFlashData, "flash data hashes mismatch");
    }

    /// @notice Verifies the staking pool configuration encoding.
    function test_encodeStakingPoolConfig_returnsExpectedPoolConfig_OK() public {
        address token = address(0x100);
        uint256 rewardRate = 100;
        uint256 lockPeriod = 100_000_000;
        uint256 maxStakers = 500;

        // Freeze block timestamp to a known value
        uint256 fixedTs = 1_700_000_000;
        vm.warp(fixedTs);

        bytes memory poolConfig = demo.encodeStakingPoolConfig(token, rewardRate, lockPeriod, maxStakers);
        bytes memory expectedPoolConfig = abi.encodePacked(token, rewardRate, lockPeriod, maxStakers, fixedTs);

        assertEq(poolConfig, expectedPoolConfig, "poolConfig hashes mismatch");
    }
}

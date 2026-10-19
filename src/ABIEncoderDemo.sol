// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

/**
 * @title ABIEncoderDemo
 * @author David Villalgordo
 * @dev This contract demo shows different uses of abi.encodePacked() in DeFi protocols.
 */
contract ABIEncoderDemo {
    //Events to show the codification
    event DataEncoded(bytes32 indexed hash, bytes encodedData);
    event PoolIdentifierCreated(bytes32 indexed poolId, address token, uint256 rate);
    event UserPositionEncoded(bytes32 indexed positionId, address user, uint256 amount);

    /**
     * @dev This function encodes the pool parameters
     * @param tokenA_ first pool token address
     * @param tokenB_ second pool token address
     * @param fee_ the pool fee
     * @return poolId identifier (unique for this pool)
     */
    function createPoolIdentifier(address tokenA_, address tokenB_, uint24 fee_)
        external
        pure
        returns (bytes32 poolId)
    {
        (address token0, address token1) = tokenA_ < tokenB_ ? (tokenA_, tokenB_) : (tokenB_, tokenA_);
        poolId = keccak256(abi.encodePacked(token0, token1, fee_));
    }

    /**
     * @notice Encodes a trading position and derives its unique identifier.
     * @param user_ Address of the user who owns the position.
     * @param tokenIn_ Address of the input token.
     * @param tokenOut_ Address of the output token.
     * @param amountIn_ Amount of input tokens.
     * @param amountOut_ Amount of output tokens.
     * @return positionId Hash identifying the encoded position.
     * @return encodedData Packed position data, including the current block timestamp.
     */
    function encodeTradingPosition(
        address user_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOut_
    ) external view returns (bytes32 positionId, bytes memory encodedData) {
        // Encode the position data
        encodedData = abi.encodePacked(user_, tokenIn_, tokenOut_, amountIn_, amountOut_, block.timestamp);

        // Unique identifier for the position
        positionId = keccak256(encodedData);
    }

    /**
     * @notice Packs a token path, corresponding amounts, and a deadline into swap data.
     * @param path_ Token addresses that define the swap path.
     * @param amounts_ Amounts corresponding to the token path.
     * @param deadline_ Timestamp after which the swap is no longer valid.
     * @return swapData Packed swap data.
     */
    function encodeSwapData(address[] calldata path_, uint256[] calldata amounts_, uint256 deadline_)
        external
        pure
        returns (bytes memory swapData)
    {
        require(path_.length == amounts_.length, "Array length mismatch");

        // Encode the path
        bytes memory encodedPath;
        for (uint256 i = 0; i < path_.length; i++) {
            encodedPath = abi.encodePacked(encodedPath, path_[i]);
        }

        // Encode the amounts
        bytes memory encodedAmounts;
        for (uint256 i = 0; i < amounts_.length; i++) {
            encodedAmounts = abi.encodePacked(encodedAmounts, amounts_[i]);
        }

        // Combine both encodes
        swapData = abi.encodePacked(encodedPath, encodedAmounts, deadline_);
    }

    /**
     * @notice Encodes a limit order and derives its unique hash.
     * @param maker_ Address of the order maker.
     * @param taker_ Address of the intended order taker.
     * @param tokenIn_ Address of the input token.
     * @param tokenOut_ Address of the output token.
     * @param amountIn_ Amount of input tokens.
     * @param amountOut_ Amount of output tokens.
     * @param nonce_ Unique nonce for the order.
     * @return orderHash Hash identifying the encoded limit order.
     * @return orderData Packed order data, including the limit-order version tag.
     */
    function encodeLimitOrder(
        address maker_,
        address taker_,
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_,
        uint256 amountOut_,
        uint256 nonce_
    ) external pure returns (bytes32 orderHash, bytes memory orderData) {
        orderData = abi.encodePacked(
            maker_, taker_, tokenIn_, tokenOut_, amountIn_, amountOut_, nonce_, "LIMIT_ORDER_V1"
        );
        orderHash = keccak256(orderData);
    }

    /**
     * @notice Derives a unique identifier for a yield position.
     * @param user_ Address of the user who owns the position.
     * @param poolId_ Identifier of the pool containing the position.
     * @param amount_ Amount deposited in the position.
     * @param startTime_ Timestamp when the position started.
     * @return positionId Hash identifying the encoded yield position.
     */
    function encodeYieldPosition(address user_, bytes32 poolId_, uint256 amount_, uint256 startTime_)
        external
        pure
        returns (bytes32 positionId)
    {
        positionId = keccak256(abi.encodePacked(user_, poolId_, amount_, startTime_, "YIELD_POSITION"));
    }

    /**
     * @notice Packs flash-loan parameters and callback data with a version tag.
     * @param token_ Address of the flash-loan token.
     * @param amount_ Amount of tokens borrowed.
     * @param callbackData_ Data passed to the flash-loan callback.
     * @return flashData Packed flash-loan data.
     */
    function encodeFlashLoanData(address token_, uint256 amount_, bytes calldata callbackData_)
        external
        pure
        returns (bytes memory flashData)
    {
        flashData = abi.encodePacked(token_, amount_, callbackData_, "FLASH_LOAN_V1");
    }

    /**
     * @notice Packs staking-pool configuration with the current block timestamp.
     * @param token_ Address of the staking or reward token.
     * @param rewardRate_ Reward rate configured for the pool.
     * @param lockPeriod_ Required lock period for staked tokens.
     * @param maxStakers_ Maximum number of stakers allowed in the pool.
     * @return poolConfig Packed pool configuration data.
     */
    function encodeStakingPoolConfig(address token_, uint256 rewardRate_, uint256 lockPeriod_, uint256 maxStakers_)
        external
        view
        returns (bytes memory poolConfig)
    {
        poolConfig = abi.encodePacked(token_, rewardRate_, lockPeriod_, maxStakers_, block.timestamp);
    }
}

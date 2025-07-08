// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {IBasePool} from "lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/IBasePool.sol";
import {BalancerPoolToken} from "lib/balancer-v3-monorepo/pkg/vault/contracts/BalancerPoolToken.sol";
import {FixedPoint} from "lib/balancer-v3-monorepo/pkg/solidity-utils/contracts/math/FixedPoint.sol";
import {WeightedMath} from "lib/balancer-v3-monorepo/pkg/solidity-utils/contracts/math/WeightedMath.sol";
import {Rounding} from "lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/VaultTypes.sol";
import {SwapKind} from "lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/VaultTypes.sol";
import {PoolSwapParams} from "lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/VaultTypes.sol";
import {TokenConfig} from "lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/VaultTypes.sol";
import {PoolRoleAccounts} from "lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/VaultTypes.sol";
import {IVault} from "lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/IVault.sol";
import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

// lib/balancer-v3-monorepo/pkg/interfaces/contracts/solidity-utils/helpers/IRateProvider.sol

contract BondPool is IBasePool, BalancerPoolToken {
    using FixedPoint for uint256;

    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 0;
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 0.1e18; // 10%

    constructor(IVault vault, string memory name, string memory symbol) BalancerPoolToken(vault, name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @notice Execute a swap in the pool.
     * @param params Swap parameters
     * @return amountCalculatedScaled18 Calculated amount for the swap
     */
    function onSwap(PoolSwapParams calldata params) external pure returns (uint256 amountCalculatedScaled18) {
        uint256 poolBalancetokenIn = params.balancesScaled18[params.indexIn]; // X
        uint256 poolBalancetokenOut = params.balancesScaled18[params.indexOut]; // Y

        if (params.kind == SwapKind.EXACT_IN) {
            uint256 amountTokenIn = params.amountGivenScaled18; // dx
            // dy = (Y * dx) / (X + dx)
            amountCalculatedScaled18 = (poolBalancetokenOut * amountTokenIn) / (poolBalancetokenIn + amountTokenIn);
        } else {
            uint256 amountTokenOut = params.amountGivenScaled18; // dy
            // dx = (X * dy) / (Y - dy)
            amountCalculatedScaled18 = (poolBalancetokenIn * amountTokenOut) / (poolBalancetokenOut - amountTokenOut);
        }
    }

    /**
     * @notice Computes and returns the pool's invariant.
     * @dev This function computes the invariant based on current balances.
     * @param balancesLiveScaled18 Token balances after paying yield fees, applying decimal scaling and rates
     * @param rounding Rounding direction to consider when computing the invariant
     * @return invariant The calculated invariant of the pool, represented as a uint256
     */
    function computeInvariant(uint256[] memory balancesLiveScaled18, Rounding rounding)
        public
        pure
        returns (uint256 invariant)
    {
        // expected to work with 2 tokens only.
        invariant = FixedPoint.ONE;
        for (uint256 i = 0; i < balancesLiveScaled18.length; ++i) {
            invariant = rounding == Rounding.ROUND_DOWN
                ? invariant.mulDown(balancesLiveScaled18[i])
                : invariant.mulUp(balancesLiveScaled18[i]);
        }
        // scale the invariant to 1e18
        invariant = Math.sqrt(invariant) * 1e9;
    }

    /**
     * @notice Computes the new balance of a token after an operation.
     * @dev This takes into account the invariant growth ratio and all other balances.
     * @param balancesLiveScaled18 Current live balances (adjusted for decimals, rates, etc.)
     * @param tokenInIndex The index of the token we're computing the balance for, in token registration order
     * @param invariantRatio The ratio of the new invariant (after an operation) to the old
     * @return newBalance The new balance of the selected token, after the operation
     */
    function computeBalance(uint256[] memory balancesLiveScaled18, uint256 tokenInIndex, uint256 invariantRatio)
        external
        pure
        returns (uint256 newBalance)
    {
        uint256 otherTokenIndex = tokenInIndex == 0 ? 1 : 0;

        uint256 newInvariant = computeInvariant(balancesLiveScaled18, Rounding.ROUND_DOWN).mulDown(invariantRatio);

        newBalance = (newInvariant * newInvariant / balancesLiveScaled18[otherTokenIndex]);
    }

    function getMinimumSwapFeePercentage() external pure returns (uint256) {
        return _MIN_SWAP_FEE_PERCENTAGE;
    }

    function getMaximumSwapFeePercentage() external pure returns (uint256) {
        return _MAX_SWAP_FEE_PERCENTAGE;
    }

    function getMinimumInvariantRatio() external pure returns (uint256) {
        return WeightedMath._MIN_INVARIANT_RATIO;
    }

    function getMaximumInvariantRatio() external pure returns (uint256) {
        return WeightedMath._MAX_INVARIANT_RATIO;
    }
}

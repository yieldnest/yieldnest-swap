// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {TokenConfig, PoolRoleAccounts} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IVaultErrors} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";
import {IPoolInfo} from "@balancer-labs/v3-interfaces/contracts/pool-utils/IPoolInfo.sol";
import {IBasePool} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    IWeightedPool,
    WeightedPoolImmutableData,
    WeightedPoolDynamicData
} from "@balancer-labs/v3-interfaces/contracts/pool-weighted/IWeightedPool.sol";

import {CastingHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import {InputHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import {ArrayHelpers} from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import {WeightedMath} from "@balancer-labs/v3-solidity-utils/contracts/math/WeightedMath.sol";
import {BasePoolTest} from "@balancer-labs/v3-vault/test/foundry/utils/BasePoolTest.sol";
import {PoolFactoryMock} from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import {PoolHooksMock} from "@balancer-labs/v3-vault/contracts/test/PoolHooksMock.sol";
import {LiquidityManagement} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {BondPool} from "../src/BondPool.sol";
import {BondPoolFactory} from "../src/BondPoolFactory.sol";
import {BondPoolContractsDeployer} from "../src/BondPoolContractDeployer.sol";

contract BondPoolTest is BondPoolContractsDeployer, BasePoolTest {
    using CastingHelpers for address[];
    using ArrayHelpers for *;

    string constant POOL_VERSION = "Pool v1";
    uint256 constant DEFAULT_SWAP_FEE = 1e16; // 1%
    uint256 constant TOKEN_AMOUNT = 1e3 * 1e18;

    uint256[] internal weights;

    uint256 daiIdx;
    uint256 usdcIdx;

    function setUp() public virtual override {
        expectedAddLiquidityBptAmountOut = TOKEN_AMOUNT;
        tokenAmountIn = TOKEN_AMOUNT / 4;
        isTestSwapFeeEnabled = false;

        BasePoolTest.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));

        poolMinSwapFeePercentage = 0;
        poolMaxSwapFeePercentage = 10e16;
    }

    function createPoolFactory() internal override returns (address) {
        return address(deployBondPoolFactory(IVault(address(vault)), 365 days));
    }

    function createPool() internal override returns (address newPool, bytes memory poolArgs) {
        string memory name = "ERC20 Pool";
        string memory symbol = "ERC20POOL";

        IERC20[] memory sortedTokens = InputHelpers.sortTokens([address(dai), address(usdc)].toMemoryArray().asIERC20());
        for (uint256 i = 0; i < sortedTokens.length; i++) {
            poolTokens.push(sortedTokens[i]);
            tokenAmounts.push(TOKEN_AMOUNT);
        }

        uint256 feePercentage = 1e16;
        bool protocolFeeExempt = false;

        PoolRoleAccounts memory roleAccounts;
        // Allow pools created by `factory` to use poolHooksMock hooks
        PoolHooksMock(poolHooksContract).allowFactory(poolFactory);

        newPool = BondPoolFactory(poolFactory).create(
            name,
            symbol,
            "", // salt
            vault.buildTokenConfig(sortedTokens),
            feePercentage,
            protocolFeeExempt,
            roleAccounts,
            poolHooksContract,
            LiquidityManagement({
                disableUnbalancedLiquidity: false,
                enableAddLiquidityCustom: false,
                enableRemoveLiquidityCustom: false,
                enableDonation: false
            })
        );
    }

    function initPool() internal override {
        vm.startPrank(lp);
        bptAmountOut = _initPool(
            pool,
            tokenAmounts,
            // Account for the precision loss
            expectedAddLiquidityBptAmountOut - DELTA
        );
        vm.stopPrank();
    }

    //     function testFailSwapFeeTooLow() public {
    //         TokenConfig[] memory tokenConfigs = new TokenConfig[](2);
    //         tokenConfigs[daiIdx].token = IERC20(dai);
    //         tokenConfigs[usdcIdx].token = IERC20(usdc);

    //         PoolRoleAccounts memory roleAccounts;

    //         address lowFeeWeightedPool = WeightedPoolFactory(poolFactory).create(
    //             "ERC20 Pool",
    //             "ERC20POOL",
    //             tokenConfigs,
    //             [uint256(50e16), uint256(50e16)].toMemoryArray(),
    //             roleAccounts,
    //             IBasePool(pool).getMinimumSwapFeePercentage() - 1, // Swap fee too low
    //             poolHooksContract,
    //             false, // Do not enable donations
    //             false, // Do not disable unbalanced add/remove liquidity
    //             "Low fee pool"
    //         );

    //         vm.expectRevert(IVaultErrors.SwapFeePercentageTooLow.selector);
    //         PoolFactoryMock(poolFactory).registerTestPool(lowFeeWeightedPool, tokenConfigs);
    //     }

    //     function testGetWeightedPoolImmutableData() public view {
    //         WeightedPoolImmutableData memory data = IWeightedPool(pool).getWeightedPoolImmutableData();
    //         (uint256[] memory scalingFactors,) = vault.getPoolTokenRates(pool);
    //         IERC20[] memory tokens = IPoolInfo(pool).getTokens();

    //         for (uint256 i = 0; i < tokens.length; ++i) {
    //             assertEq(address(data.tokens[i]), address(tokens[i]), "Token mismatch");
    //             assertEq(data.decimalScalingFactors[i], scalingFactors[i], "Decimal scaling factors mismatch");
    //             assertEq(data.normalizedWeights[i], uint256(50e16), "Weight mismatch");
    //         }
    //     }

    //     function testGetWeightedPoolDynamicData() public view {
    //         WeightedPoolDynamicData memory data = IWeightedPool(pool).getWeightedPoolDynamicData();
    //         (, uint256[] memory tokenRates) = vault.getPoolTokenRates(pool);
    //         IERC20[] memory tokens = IPoolInfo(pool).getTokens();
    //         uint256 totalSupply = IERC20(pool).totalSupply();

    //         assertTrue(data.isPoolInitialized, "Pool not initialized");
    //         assertFalse(data.isPoolPaused, "Pool paused");
    //         assertFalse(data.isPoolInRecoveryMode, "Pool in Recovery Mode");
    //         assertEq(data.totalSupply, totalSupply, "Total supply mismatch");
    //         assertEq(data.staticSwapFeePercentage, DEFAULT_SWAP_FEE, "Swap fee mismatch");

    //         for (uint256 i = 0; i < tokens.length; ++i) {
    //             assertEq(data.balancesLiveScaled18[i], DEFAULT_AMOUNT, "Live balance mismatch");
    //             assertEq(data.tokenRates[i], tokenRates[i], "Token rate mismatch");
    //         }
    //     }
}

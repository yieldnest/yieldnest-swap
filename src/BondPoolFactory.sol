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
import {LiquidityManagement} from "lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/VaultTypes.sol";
import {IVault} from "lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/IVault.sol";
import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {BasePoolFactory} from "lib/balancer-v3-monorepo/pkg/pool-utils/contracts/BasePoolFactory.sol";
import {BondPool} from "./BondPool.sol";

contract BondPoolFactory is BasePoolFactory {
    // Each factory can only deploy one type of custom pool
    constructor(IVault vault, uint32 pauseWindowDuration)
        BasePoolFactory(vault, pauseWindowDuration, type(BondPool).creationCode)
    {}

    // Streamline the process of deploying and registering a pool
    function create(
        string memory name,
        string memory symbol,
        bytes32 salt,
        TokenConfig[] memory tokens,
        uint256 swapFeePercentage,
        bool protocolFeeExempt,
        PoolRoleAccounts memory roleAccounts,
        address poolHooksContract,
        LiquidityManagement memory liquidityManagement
    ) external returns (address pool) {
        // Deploy a new pool
        pool = _create(abi.encode(getVault(), name, symbol), salt);
        // Register the pool
        _registerPoolWithVault(
            pool, tokens, swapFeePercentage, protocolFeeExempt, roleAccounts, poolHooksContract, liquidityManagement
        );
    }
}

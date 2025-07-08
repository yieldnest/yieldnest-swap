// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

import {BaseContractsDeployer} from "@balancer-labs/v3-solidity-utils/test/foundry/utils/BaseContractsDeployer.sol";

import {BondPool} from "./BondPool.sol";
import {BondPoolFactory} from "./BondPoolFactory.sol";

/**
 * @dev This contract contains functions for deploying mocks and contracts related to the "BondPool". These functions should have support for reusing artifacts from the hardhat compilation.
 */
contract BondPoolContractsDeployer is BaseContractsDeployer {
    string private artifactsRootDir = "artifacts/";

    constructor() {
        // if this external artifact path exists, it means we are running outside of this repo
        if (vm.exists("artifacts/@balancer-labs/v3-pool-weighted/")) {
            artifactsRootDir = "artifacts/@balancer-labs/v3-pool-weighted/";
        }
    }

    function deployBondPoolFactory(IVault vault, uint32 pauseWindowDuration) internal returns (BondPoolFactory) {
        if (reusingArtifacts) {
            return BondPoolFactory(
                deployCode(_computeWeightedPath(type(BondPoolFactory).name), abi.encode(vault, pauseWindowDuration))
            );
        } else {
            return new BondPoolFactory(vault, pauseWindowDuration);
        }
    }

    function _computeWeightedPath(string memory name) private view returns (string memory) {
        return string(abi.encodePacked(artifactsRootDir, "contracts/", name, ".sol/", name, ".json"));
    }

    function _computeWeightedPathTest(string memory name) private view returns (string memory) {
        return string(abi.encodePacked(artifactsRootDir, "contracts/test/", name, ".sol/", name, ".json"));
    }
}

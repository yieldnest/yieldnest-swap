// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@balancer-v3-monorepo/interfaces/vault/IVault.sol";
import "@balancer-v3-monorepo/interfaces/vault/VaultTypes.sol";

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}

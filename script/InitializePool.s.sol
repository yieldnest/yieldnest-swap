// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {IRouter} from "@balancer-v3-monorepo/interfaces/vault/IRouter.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IPermit2} from "@permit2/interfaces/IPermit2.sol";

/**
 * To run against a local fork, start anvil:
 * `$ anvil --fork-url RPC_URL
 * Run script (in simulation mode):
 * `$ forge script script/InitializePool.s.sol:InitializePool --fork-url http://localhost:8545
 */
contract InitializePool is Script {
    // Balancer Router
    IRouter public constant router = IRouter(0x0BF61f706105EA44694f2e92986bD01C39930280);
    IPermit2 public constant permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    // Pool to init
    address public constant pool = 0x80fd5bc9d4fA6C22132f8bb2d9d30B01c3336FB3;
    IERC20 dai = IERC20(0xB77EB1A70A96fDAAeB31DB1b42F2b8b5846b2613);
    IERC20 bal = IERC20(0xb19382073c7A0aDdbb56Ac6AF1808Fa49e377B75);

    function run() public returns (uint256) {
        // Add .env in root with PRIVATE_KEY
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        bal.approve(address(permit2), 1e18);
        dai.approve(address(permit2), 1e18);
        permit2.approve(address(bal), address(router), type(uint160).max, type(uint48).max);
        permit2.approve(address(dai), address(router), type(uint160).max, type(uint48).max);

        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = bal;
        tokens[1] = dai;

        uint256[] memory exactAmountsIn = new uint256[](2);
        exactAmountsIn[0] = 1e18;
        exactAmountsIn[1] = 1e18;

        router.initialize(pool, tokens, exactAmountsIn, 0, false, bytes(""));

        vm.stopBroadcast();

        return 0;
    }
}

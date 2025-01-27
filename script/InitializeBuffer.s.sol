// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {IBufferRouter} from "@balancer-v3-monorepo/interfaces/vault/IBufferRouter.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IPermit2} from "@permit2/interfaces/IPermit2.sol";

contract InitializeBuffer is Script {
    IERC20 public constant solvBtc = IERC20(0x541FD749419CA806a8bc7da8ac23D346f2dF8B77);
    IERC20 public constant solvBtcBbn = IERC20(0xCC0966D8418d412c599A6421b760a847eB169A8c);
    IERC20 public constant usdc = IERC20(0x29219dd400f2Bf60E5a23d13Be72B486D4038894);
    IPermit2 public constant permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IBufferRouter public constant bufferRouter = IBufferRouter(0x532dA919D3EB5606b5867A6f505969c57F3A721b);

    function run() public returns (uint256) {
        vm.startBroadcast();

        usdc.approve(address(permit2), 100_000_000e18);
        permit2.approve(address(usdc), address(bufferRouter), type(uint160).max, type(uint48).max);

        /* bufferRouter.initializeBuffer(
            IERC4626(0x7870ddFd5ACA4E977B2287e9A212bcbe8FC4135a),
            1_000_000, //exactAmountUnderlyingIn,
            0, //exactAmountWrappedIn,
            0 //minIssuedShares
        ); */

        vm.stopBroadcast();

        return 0;
    }
}

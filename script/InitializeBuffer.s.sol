// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {IBufferRouter} from "@balancer-v3-monorepo/interfaces/vault/IBufferRouter.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IPermit2} from "@permit2/interfaces/IPermit2.sol";

contract InitializeBuffer is Script {
    IPermit2 public constant permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IBufferRouter public constant bufferRouter = IBufferRouter(0x532dA919D3EB5606b5867A6f505969c57F3A721b);
    IERC4626 public constant wrapper = IERC4626(0x7870ddFd5ACA4E977B2287e9A212bcbe8FC4135a);

    function run() public returns (uint256) {
        vm.startBroadcast();

        address asset = wrapper.asset();

        IERC20(asset).approve(address(permit2), 100_000_000e18);
        permit2.approve(address(asset), address(bufferRouter), type(uint160).max, type(uint48).max);

        bufferRouter.initializeBuffer(
            wrapper,
            1_000_000, //exactAmountUnderlyingIn,
            0, //exactAmountWrappedIn,
            0 //minIssuedShares
        );

        vm.stopBroadcast();

        return 0;
    }
}

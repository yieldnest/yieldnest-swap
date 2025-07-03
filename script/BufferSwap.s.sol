// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {IBatchRouter} from "@balancer-v3-monorepo/interfaces/vault/IBatchRouter.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IPermit2} from "@permit2/interfaces/IPermit2.sol";

contract BufferSwap is Script {
    IBatchRouter public constant batchRouter = IBatchRouter(0x7761659F9e9834ad367e4d25E0306ba7A4968DAf);
    IPermit2 public constant permit2 = IPermit2(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    IERC20 public constant usdc = IERC20(0x29219dd400f2Bf60E5a23d13Be72B486D4038894);
    IERC20 public constant waUsdc = IERC20(0x6646248971427B80ce531bdD793e2Eb859347E55);
    IERC20 public constant wstkscUsd = IERC20(0x9fb76f7ce5FCeAA2C42887ff441D46095E494206);
    address public constant boostedDollarPool = 0x54Ca9aad90324C022bBeD0A94b7380c03aA5884A;

    function run() public returns (uint256) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // permit2 approvals
        IERC20(usdc).approve(address(permit2), 100_000_000e18);
        IERC20(wstkscUsd).approve(address(permit2), 100_000_000e18);
        permit2.approve(address(usdc), address(batchRouter), type(uint160).max, type(uint48).max);
        permit2.approve(address(wstkscUsd), address(batchRouter), type(uint160).max, type(uint48).max);

        // swap USDC to wstkscUsd
        IBatchRouter.SwapPathExactAmountIn[] memory swapPath = new IBatchRouter.SwapPathExactAmountIn[](1);
        // The tokenIn here is the token being taken from the user, usdc in this case
        swapPath[0].tokenIn = usdc;
        swapPath[0].exactAmountIn = 1e6;
        swapPath[0].minAmountOut = 0;

        IBatchRouter.SwapPathStep[] memory swapPathSteps = new IBatchRouter.SwapPathStep[](2);
        swapPathSteps[0].pool = address(waUsdc);
        // The tokenOut of this step is used as the tokenIn of the next step
        swapPathSteps[0].tokenOut = waUsdc;
        // notice that isBuffer == true here, because waUsdc is an ERC4626 Buffer
        swapPathSteps[0].isBuffer = true;
        swapPathSteps[1].pool = boostedDollarPool;
        // This is the final token out, it will be transferred to the user
        swapPathSteps[1].tokenOut = wstkscUsd;
        swapPathSteps[1].isBuffer = false;

        swapPath[0].steps = swapPathSteps;

        batchRouter.swapExactIn(swapPath, 999999999999999, false, "");

        // swap wstkscUsd to usdc
        IBatchRouter.SwapPathExactAmountIn[] memory swapPath2 = new IBatchRouter.SwapPathExactAmountIn[](1);
        swapPath2[0].tokenIn = wstkscUsd;
        swapPath2[0].exactAmountIn = 1e6;
        swapPath2[0].minAmountOut = 0;

        IBatchRouter.SwapPathStep[] memory swapPathSteps2 = new IBatchRouter.SwapPathStep[](2);
        swapPathSteps2[0].pool = address(boostedDollarPool);
        swapPathSteps2[0].tokenOut = waUsdc;
        swapPathSteps2[0].isBuffer = false;
        swapPathSteps2[1].pool = address(waUsdc);
        swapPathSteps2[1].tokenOut = usdc;
        // Notice that isBuffer == true here, this signals to the router that we want to unwrap waUSDC and received USDC
        swapPathSteps2[1].isBuffer = true;

        swapPath2[0].steps = swapPathSteps2;

        batchRouter.swapExactIn(swapPath2, 999999999999999, false, "");

        vm.stopBroadcast();

        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * To run against a local fork, start anvil:
 * `$ anvil --fork-url RPC_URL
 * Run script (in simulation mode):
 * `$ forge script script/GyroECLPCreate.s.sol:GyroECLPCreate --fork-url http://localhost:8545
 */
struct LBPParams {
    address owner;
    IERC20 projectToken;
    IERC20 reserveToken;
    uint256 projectTokenStartWeight;
    uint256 reserveTokenStartWeight;
    uint256 projectTokenEndWeight;
    uint256 reserveTokenEndWeight;
    uint256 startTime;
    uint256 endTime;
    bool blockProjectTokenSwapsIn;
}

interface ILBPoolFactory {
    /**
     * @notice Deploys a new `LBPool`.
     * @dev This method does not support native ETH management; WETH needs to be used instead.
     * @param name The name of the pool
     * @param symbol The symbol of the pool
     * @param lbpParams The LBP configuration (see ILBPool for the struct definition)
     * @param swapFeePercentage Initial swap fee percentage (bound by the WeightedPool range)
     * @param salt The salt value that will be passed to create3 deployment
     * @return pool The address of the newly created pool
     */
    function create(
        string memory name,
        string memory symbol,
        LBPParams memory lbpParams,
        uint256 swapFeePercentage,
        bytes32 salt
    ) external returns (address pool);
}

contract LBPoolCreate is Script {
    // factory on sepolia
    ILBPoolFactory poolFactory = ILBPoolFactory(0xA714753434481DbaBf7921963f18190636eCde69);
    // tokens on sepolia
    IERC20 dai = IERC20(0xB77EB1A70A96fDAAeB31DB1b42F2b8b5846b2613);
    IERC20 bal = IERC20(0xb19382073c7A0aDdbb56Ac6AF1808Fa49e377B75);

    function run() public returns (uint256) {
        // Add .env in root with PRIVATE_KEY
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Creating LB Pool...");

        LBPParams memory lbpParams;
        lbpParams.owner = msg.sender;
        lbpParams.projectToken = dai;
        lbpParams.reserveToken = bal;
        lbpParams.projectTokenStartWeight = 500000000000000000; // 50%
        lbpParams.reserveTokenStartWeight = 500000000000000000; // 50%
        lbpParams.projectTokenEndWeight = 200000000000000000; // 20%
        lbpParams.reserveTokenEndWeight = 800000000000000000; // 80%
        lbpParams.startTime = block.timestamp + 3600; // Start in 1 hour
        lbpParams.endTime = block.timestamp + 7200; // End in 2 hours
        lbpParams.blockProjectTokenSwapsIn = false;

        address pool = poolFactory.create(
            "My LB Pool",
            "LBP",
            lbpParams,
            1e16, // Swap fee percentage (1%)
            bytes32(msg.sender)
        );

        console.log("LB Pool created at:", pool);

        vm.stopBroadcast();
        return uint256(uint160(pool));
    }
}

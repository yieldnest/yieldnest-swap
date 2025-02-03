// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IBufferRouter} from "@balancer-v3-monorepo/interfaces/vault/IBufferRouter.sol";
import {TokenConfig, PoolRoleAccounts, TokenType} from "@balancer-v3-monorepo/interfaces/vault/VaultTypes.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IPermit2} from "@permit2/interfaces/IPermit2.sol";

/**
 * To run against a local fork, start anvil:
 * `$ anvil --fork-url RPC_URL
 * Run script (in simulation mode):
 * `$ forge script script/StableSurgeCreate.s.sol:StableSurgeCreate --fork-url http://localhost:8545
 */
interface IStableSurgePoolFactory {
    function create(
        string memory name,
        string memory symbol,
        TokenConfig[] memory tokens,
        uint256 amplificationParameter,
        PoolRoleAccounts memory roleAccounts,
        uint256 swapFeePercentage,
        bool enableDonation,
        bool disableUnbalancedLiquidity,
        bytes32 salt
    ) external returns (address pool);
    function getPoolCount() external view returns (uint256);
}

contract StableSurgeCreate is Script {
    IStableSurgePoolFactory poolFactory = IStableSurgePoolFactory(0x9eB9867C1d4B6fd3a7D0dAd3101b5A153b1107Ec);
    IERC20 weth = IERC20(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9);
    IERC20 bal = IERC20(0xb19382073c7A0aDdbb56Ac6AF1808Fa49e377B75);

    function run() public returns (uint256) {
        // Add .env in root with PRIVATE_KEY
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.logUint(poolFactory.getPoolCount());

        PoolRoleAccounts memory roleAccounts;
        TokenConfig memory t1;
        t1.token = weth;
        t1.tokenType = TokenType.STANDARD;
        TokenConfig memory t2;
        t2.token = bal;
        t2.tokenType = TokenType.STANDARD;
        TokenConfig[] memory tokenConfigs = new TokenConfig[](2);
        tokenConfigs[0] = t1;
        tokenConfigs[1] = t2;
        address newPool = poolFactory.create(
            "T1-TEST", // Name
            "T1", // Symbol
            sortTokenConfig(tokenConfigs), // tokens
            1000, // amp
            roleAccounts, // roleAccounts
            10000000000000000, // swapFeePercentage
            false, // enableDonation
            false, // disableUnbalancedLiquidity
            bytes32("salt1")
        );

        console.log(newPool);

        console.logUint(poolFactory.getPoolCount());

        vm.stopBroadcast();

        return 0;
    }

    function sortTokenConfig(TokenConfig[] memory tokenConfig) public pure returns (TokenConfig[] memory) {
        for (uint256 i = 0; i < tokenConfig.length - 1; ++i) {
            for (uint256 j = 0; j < tokenConfig.length - i - 1; j++) {
                if (tokenConfig[j].token > tokenConfig[j + 1].token) {
                    // Swap if they're out of order.
                    (tokenConfig[j], tokenConfig[j + 1]) = (tokenConfig[j + 1], tokenConfig[j]);
                }
            }
        }

        return tokenConfig;
    }
}

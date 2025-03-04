// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IGyroECLPPool} from "@balancer-v3-monorepo/interfaces/pool-gyro/IGyroECLPPool.sol";
import {TokenConfig, PoolRoleAccounts, TokenType} from "@balancer-v3-monorepo/interfaces/vault/VaultTypes.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * To run against a local fork, start anvil:
 * `$ anvil --fork-url RPC_URL
 * Run script (in simulation mode):
 * `$ forge script script/GyroECLPCreate.s.sol:GyroECLPCreate --fork-url http://localhost:8545
 */
interface IGyroECLPPoolFactory {
    function create(
        string memory name,
        string memory symbol,
        TokenConfig[] memory tokens,
        IGyroECLPPool.EclpParams memory eclpParams,
        IGyroECLPPool.DerivedEclpParams memory derivedEclpParams,
        PoolRoleAccounts memory roleAccounts,
        uint256 swapFeePercentage,
        address poolHooksContract,
        bool enableDonation,
        bool disableUnbalancedLiquidity,
        bytes32 salt
    ) external returns (address pool);
    function getPoolCount() external view returns (uint256);
}

contract GyroECLPCreate is Script {
    IGyroECLPPoolFactory poolFactory = IGyroECLPPoolFactory(0x2255b6a03A6eDd0D6CC670864F297869063FE00F);
    IERC20 dai = IERC20(0xB77EB1A70A96fDAAeB31DB1b42F2b8b5846b2613);
    IERC20 bal = IERC20(0xb19382073c7A0aDdbb56Ac6AF1808Fa49e377B75);

    function run() public returns (uint256) {
        // Add .env in root with PRIVATE_KEY
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.logUint(poolFactory.getPoolCount());

        PoolRoleAccounts memory roleAccounts;
        TokenConfig memory t1;
        t1.token = dai;
        t1.tokenType = TokenType.STANDARD;
        TokenConfig memory t2;
        t2.token = bal;
        t2.tokenType = TokenType.STANDARD;
        TokenConfig[] memory tokenConfigs = new TokenConfig[](2);
        tokenConfigs[0] = t1;
        tokenConfigs[1] = t2;
        IGyroECLPPool.EclpParams memory eclpParams;
        eclpParams.alpha = 998502246630054917;
        eclpParams.beta = 1000200040008001600;
        eclpParams.c = 707106781186547524;
        eclpParams.s = 707106781186547524;
        eclpParams.lambda = 4000000000000000000000;
        IGyroECLPPool.DerivedEclpParams memory derivedEclpParams;
        derivedEclpParams.tauAlpha.x = -94861212813096057289512505574275160547;
        derivedEclpParams.tauAlpha.y = 31644119574235279926451292677567331630;
        derivedEclpParams.tauBeta.x = 37142269533113549537591131345643981951;
        derivedEclpParams.tauBeta.y = 92846388265400743995957747409218517601;
        derivedEclpParams.u = 66001741173104803338721745994955553010;
        derivedEclpParams.v = 62245253919818011890633399060291020887;
        derivedEclpParams.w = 30601134345582732000058913853921008022;
        derivedEclpParams.z = -28859471639991253843240999485797747790;
        derivedEclpParams.dSq = 99999999999999999886624093342106115200;

        address newPool = poolFactory.create(
            "T1-TEST", // Name
            "T1", // Symbol
            sortTokenConfig(tokenConfigs), // tokens
            eclpParams,
            derivedEclpParams,
            roleAccounts, // roleAccounts
            10000000000000000, // swapFeePercentage
            address(0),
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

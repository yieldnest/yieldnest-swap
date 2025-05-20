# Foundry Starter

Example foundry scripts for interacting with Balancer v3

1. Ensure you have the latest version of foundry installed

```
foundryup
```

2. Clone repo and install dependencies

```
git clone https://github.com/balancer/balancer-v3-foundry-starter.git
cd bbalancer-v3-foundry-starter/
forge install
```

3. Create a `.env` file in the root of the project

```
PRIVATE_KEY=
SEPOLIA_RPC_URL=
MAINNET_RPC_URL=
```

4. Simulate a script

```
forge script script/GyroResolvECLPCreate.s.sol:GyroResolvECLPCreate --rpc-url sepolia
```

5. Broadcast a script

```
forge script script/GyroResolvECLPCreate.s.sol:GyroResolvECLPCreate --rpc-url sepolia --broadcast
```

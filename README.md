<div align="center">
  <h1>ImmutableDeploymentFactory</h1>
</div>

<div align="center">
  <h3><i>..deterministic omni-chain smart contract deployments</i></h3>
  <br>
  The <code>ImmutableDeploymentFactory</code> can be used to deterministically deploy immutable smart contracts on any EVM-compatible chain to the same address using both <code>create2</code> and <code>create3</code> deployment functions. 
  <br>
  <br>
  Contracts deployed with this factory are immutable, and cannot be overwritten. Salts used for deployment can optionally include the caller's address to prevent front-running.
  <br>
  <br>
  <a href="https://badge.fury.io/js/@vitriollabs%2Fimmutable-deployment-factory"><img src="https://badge.fury.io/js/@vitriollabs%2Fimmutable-deployment-factory.svg" alt="npm version" height="18"></a>
  <br>
</div>

***

## Usage:

The following functions are available to based on hash and deployment method (create2/3)

- `findCreate[#]Address` - find contract deployment address based on salt
- `safeCreate[#]Address` - perform contract deployment based on salt

```solidity
function safeCreate2(bytes32 salt, bytes calldata initializationCode) returns (address deploymentAddress);
function findCreate2Address(bytes32 salt, bytes calldata initCode) returns (address deploymentAddress);
function findCreate2AddressViaHash(bytes32 salt, bytes32 initCodeHash) returns (address deploymentAddress);

function safeCreate3(bytes32 salt, bytes calldata initializationCode) returns (address deploymentAddress);
function findCreate3Address(bytes32 salt) returns (address deploymentAddress);
```

> Note: <code>create2</code> deployment addresses are influenced by the deploying contract's bytecode 

## Deployment:

The `ImmutableDeploymentFactory` has been deployed to `0x0000086e1910D5977302116fC27934DC0254266C` on the following networks:
  - Ethereum 
    - [Mainnet](https://etherscan.io/address/0x0000086e1910d5977302116fc27934dc0254266c)
    - [Goerli Testnet](https://goerli.etherscan.io/address/0x0000086e1910d5977302116fc27934dc0254266c)
    - [Sepolia Testnet](https://sepolia.etherscan.io/address/0x0000086e1910d5977302116fc27934dc0254266c)
  - Optimism
    - [Sepolia Testnet](https://sepolia-optimism.etherscan.io/address/0x0000086e1910D5977302116fC27934DC0254266C)
  - BSC
    - [Testnet](https://testnet.bscscan.com/address/0x0000086e1910d5977302116fc27934dc0254266c)

The `ImmutableDeploymentFactory` was initially deployed using [Nick's method](https://yamenmerhi.medium.com/nicks-method-ethereum-keyless-execution-168a6659479c) for keyless contract deployments. 

You can deploy a copy of the factory to any EVM compatible chain by:
1. Funding the deployment address `0x0D6470aED3287d05dF6cE19Ba4fab50852a49b5e` with `0.07` chain-currency (possibly with additional chain fees ex: L1 fees on Optimism)
2. Broadcast `signedTx` from [keylessDeployment.json](https://github.com/VitriolLabs/ImmutableDeploymentFactory/blob/main/deployment/keylessDeployment.json) when gas is less than 100 gwei. You **MUST** fund the account prior to broadcasting the transaction.

Some web3 providers filter out Type-0 transactions (Ethereum legacy transactions), which are used here for omni-chain deployment. We had success using the [Alchemy Sandbox](https://dashboard.alchemy.com/sandbox) to broadcast the deployment transactions.

## Authors / Mentions

This repo was created by [Cameron White (Slvrfn)](https://ca.meron.dev) of [Vitriol Labs](https://vitriol.sh), but would not have been possible without the contributions of:
- [0age (ImmutableCreate2Factory)](https://github.com/0age/metamorphic/blob/master/contracts/ImmutableCreate2Factory.sol) 
- [Vectorized (CREATE3)](https://github.com/Vectorized/solady).

## Contributing

Contributions are welcome, please review [CONTRIBUTIONS](https://github.com/VitriolLabs/ImmutableDeploymentFactory/blob/main/CONTRIBUTING.md) for more details.

## License

The files contained therein are licensed under The MIT License (MIT). See the [LICENSE](https://github.com/VitriolLabs/ImmutableDeploymentFactory/blob/main/LICENSE.md) file for more details.

## Disclaimer

Please review the [DISCLAIMER](https://github.com/VitriolLabs/ImmutableDeploymentFactory/blob/main/DISCLAIMER.md) for more details.

***

## Donations (beermoney):

- Eth: [vitriollabs.eth](https://etherscan.io/address/0xFe9fe85c7E894917B5a42656548a9D143f96f12E) or `0xFe9fe85c7E894917B5a42656548a9D143f96f12E` on any EVM chain.
- Btc: bc1qwf9xndxfwhfuul93seaq603xkgr64cwkc4d4dd

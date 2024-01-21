import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-solhint";
import 'hardhat-contract-sizer'

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 50000
          }
        }
      }
    ]
  },
  paths: {
    sources: "./Contracts",
    cache: "./.temp/cache",
    artifacts: "./.temp/artifacts"
  },
  contractSizer: {
    runOnCompile: true
  }
};

export default config;

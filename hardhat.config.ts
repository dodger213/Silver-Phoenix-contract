import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const infuraKey: string = process.env.INFURA_API_KEY as string;
const privateKey: string = process.env.PRIVATE_KEY ? process.env.PRIVATE_KEY as string: "";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.27",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
      // viaIR: true,
    },
  },
  networks: {
    eth_sepolia: {
      url: `https://sepolia.infura.io/v3/${infuraKey}`,
      accounts: [`0x${privateKey}`],
    },
    eth_mainnet: {
      url: `https://mainnet.infura.io/v3/${infuraKey}`,
      accounts: [`0x${privateKey}`],
    },
    base_sepolia: {
      url: "https://base-sepolia.blockpi.network/v1/rpc/public",
      accounts: [`0x${privateKey}`],
    },
    base_mainnet: {
      url: "https://mainnet.base.org",
      accounts: [`0x${privateKey}`],
    },
    holesky_testnet: {
      url: "https://ethereum-holesky-rpc.publicnode.com",
      accounts: [`0x${privateKey}`],
    },
    bsc_mainnet: {
      url: "https://bsc-dataseed1.binance.org",
      chainId: 56,
      accounts: [`0x${privateKey}`],
    },
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: [`0x${privateKey}`],
    },
    hardhat: {
      chainId: 31337,
    },
  },
  etherscan: {
    apiKey: {
      eth_mainnet: "ED2NED96C214Y891MR98PZZ1Q45VTFYZRV",
      eth_sepolia: "ED2NED96C214Y891MR98PZZ1Q45VTFYZRV",
      base_mainnet: "1SZX9N4CQNAX489BHPEW27C2FG5PPP4MB1",
      base_sepolia: "1SZX9N4CQNAX489BHPEW27C2FG5PPP4MB1", // etherscan: ED2NED96C214Y891MR98PZZ1Q45VTFYZRV BSC: 1UME8V5UP4AZHYDF7RWC78GTIXXRPJHTQY Base: 1SZX9N4CQNAX489BHPEW27C2FG5PPP4MB1
      holesky: "ED2NED96C214Y891MR98PZZ1Q45VTFYZRV",
      bsc_testnet: "1UME8V5UP4AZHYDF7RWC78GTIXXRPJHTQY"
    },
  },
  gasReporter: {
    enabled: true,
  },
  sourcify: {
    enabled: true,
  },
};

export default config;
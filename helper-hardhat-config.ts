import type { NetworkUserConfig } from "hardhat/types"

import { resolve } from "path"
import { config as dotenvConfig } from "dotenv"

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env"
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) })

const ETHER_RPC = process.env.ETHER_RPC as string
const GOERLI_RPC = process.env.GOERLI_RPC as string
const SEPOLIA_RPC = process.env.SEPOLIA_RPC as string
const OPBNB_RPC = process.env.OPBNB_RPC as string

type NetworkConfigItem = {
    name: string
    url: string
    saveDeployments?: boolean
    usdt?: string
    httpHeaders?: any
}

type NetworkConfigMap = {
    [chainId: string]: NetworkConfigItem
}

export const networkConfig: NetworkConfigMap = {
    default: {
        name: "hardhat",
        url: "localhost",
        saveDeployments: true,
    },
    1: {
        name: "ether",
        url: ETHER_RPC,
        saveDeployments: true,
    },
    5: {
        name: "goerli",
        url: GOERLI_RPC,
    },
    11155111: {
        name: "sepolia",
        url: SEPOLIA_RPC,
    },
    9088912: {
        name: "loottest",
        url: "https://testnet.rpc.lootchain.com/http",
    },
    204: {
        name: "opbnb",
        url: OPBNB_RPC,
    },
}

export const getNetworkIdFromName = async (networkIdName: string) => {
    for (const id in networkConfig) {
        if (networkConfig[id]["name"] == networkIdName) {
            return id
        }
    }
    return null
}

export function getChainConfig(chainId: number): NetworkUserConfig {
    let { name, url, saveDeployments = false } = networkConfig[chainId]
    return {
        accounts: [process.env.PRIVATE_KEY as string],
        chainId: chainId,
        url: url,
        saveDeployments: saveDeployments,
        timeout: 100000,
    }
}

export const developmentChains: string[] = ["hardhat", "localhost"]
export const VERIFICATION_BLOCK_CONFIRMATIONS = 6

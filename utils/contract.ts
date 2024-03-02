import { error } from "console"
import { run, ethers, upgrades, network } from "hardhat"
import { Contract } from "hardhat/internal/hardhat-network/stack-traces/model"
import { developmentChains } from "../helper-hardhat-config"

export class ContractUtil {
    public static async getContract(contractName: string, contractAddress: string = "") {
        if (contractAddress === "") {
            return await ethers.getContract(contractName)
        } else {
            return await ethers.getContractAt(contractName, contractAddress)
        }
    }

    static async verifyUpgradeContract(contractAddress: string): Promise<void> {
        const impl = await upgrades.erc1967.getImplementationAddress(contractAddress)
        console.info("verify impl to: ", impl)
        await this.verify(impl, [])
    }

    static async verify(contractAddress: string, args: any[]): Promise<void> {
        if (developmentChains.includes(network.name)) {
            console.info("The selected network is hardhat. Please select a network supported by Etherscan.")
            return
        }
        console.log(`Verifying contract ${contractAddress}...`)
        try {
            await run("verify:verify", {
                address: contractAddress,
                constructorArguments: args,
            })
        } catch (e: any) {
            if (e.message.toLowerCase().includes("already verified")) {
                console.log("Already verified!")
            } else {
                console.log(e)
            }
        }
    }

    static async deployContract(contractName: string, params: any[], contractAddress: string = "") {
        if (contractAddress !== "") {
            await this.verify(contractAddress, params)
            let contract = await ethers.getContractAt(contractName, contractAddress)
            return contract
        }
        console.log(`deploy contract: ${contractName}, arg: ${params}`)
        const Factory = await ethers.getContractFactory(contractName)

        const contract = await Factory.deploy(...params)
        await contract.waitForDeployment()

        contractAddress = await contract.getAddress()
        console.info(`${contractName} deployed to: ${contractAddress}`)

        await this.verify(contractAddress, params)
        return contract
    }

    static async deployUpgradeContract(contractName: string, params: any[], contractAddress: string = "") {
        if (contractAddress !== "") {
            await this.verifyUpgradeContract(contractAddress)
            let contract = await ethers.getContractAt(contractName, contractAddress)
            return contract
        }
        console.info(`deploy contract: ${contractName}, arg: ${params}`)
        const Factory = await ethers.getContractFactory(contractName)
        const contract = await upgrades.deployProxy(Factory, params, {
            initializer: "initialize",
        })
        await contract.waitForDeployment()

        contractAddress = await contract.getAddress()
        console.info(`${contractName} deployed to: ${contractAddress}`)
        await this.verifyUpgradeContract(contractAddress)
        return contract
    }

    static async upgradeContract(contractName: string, params: any[], contractAddress: string) {
        if (contractAddress == "") {
            throw new Error("empty contract address")
        }

        console.info(`upgrage contract: ${contractName}, arg: ${params}`)
        const Factory = await ethers.getContractFactory(contractName)
        const contract = await upgrades.upgradeProxy(contractAddress, Factory)
        await contract.waitForDeployment()

        contractAddress = await contract.getAddress()
        console.info(`${contractName} deployed to: ${contractAddress}`)
        await this.verifyUpgradeContract(contractAddress)
        return contract
    }
}

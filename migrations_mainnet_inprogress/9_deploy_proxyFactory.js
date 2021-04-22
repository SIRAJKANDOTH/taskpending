const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");


module.exports = async (deployer) => {
    // const yieldsterVaultMasterCopy = await YieldsterVault.deployed();
    // const apContract = await APContract.deployed();

    await deployer.deploy(
        ProxyFactory,
        "0x9475D25b49390e1dF61302Cc47C1C4d7D19BB372",
        "0xc078e9F3994bEf168e1aF3B2195A2C4149cc3f36"
    );

    // const proxyFactory = await ProxyFactory.deployed();

    console.log("Adding proxy factory to the APContract")
    // await apContract.addProxyFactory(proxyFactory.address);

};

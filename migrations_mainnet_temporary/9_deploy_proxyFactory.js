const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");


module.exports = async (deployer) => {
    const yieldsterVaultMasterCopy = await YieldsterVault.deployed();
    const apContract = await APContract.deployed();

    await deployer.deploy(
        ProxyFactory,
        yieldsterVaultMasterCopy.address,
        apContract.address
    );

    const proxyFactory = await ProxyFactory.deployed();

    console.log("Adding proxy factory to the APContract")
    await apContract.addProxyFactory(proxyFactory.address);

};

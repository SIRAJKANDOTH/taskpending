const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");


module.exports = async (deployer) => {
    // const yieldsterVaultMasterCopy = await YieldsterVault.deployed();
    // const apContract = await APContract.deployed();

    await deployer.deploy(
        ProxyFactory,
        "0x7B3CC1bc298bD4b442D891BD6f256A7f0c3533f8",
        "0xB24Ff34F5AE7F8Dde93A197FB406c1E78EEC0B25"
    );

    // const proxyFactory = await ProxyFactory.deployed();

    console.log("Adding proxy factory to the APContract")
    // await apContract.addProxyFactory(proxyFactory.address);

};

const APContract = artifacts.require("./aps/APContract.sol");
const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const LivaOne = artifacts.require("./strategies/LivaOne/LivaOneCrv.sol");
const LivaOneMinter = artifacts.require("./strategies/LivaOne/LivaOneMinter.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");

module.exports = async (deployer) => {
    const apContract = await APContract.deployed();
    const proxyFactory = await ProxyFactory.deployed();
    const lv1 = await LivaOne.deployed();
    const lvMinter = await LivaOneMinter.deployed();
    const ylVault = await YieldsterVault.deployed();
    console.log(`let apContractAddress = "${apContract.address}";\nlet proxyFactoryAddress = "${proxyFactory.address}";\nlet livaOneAddress = "${lv1.address}";\nlet livaOneMinterAddress = "${lvMinter.address}";\nlet yieldsterVaultMasterCopyAddress = "${ylVault.address}";\n`)
}
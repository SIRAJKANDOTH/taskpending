const YieldsterVault = artifacts.require("./YieldsterVault.sol");

module.exports = async (deployer) => {
    await deployer.deploy(YieldsterVault);
};

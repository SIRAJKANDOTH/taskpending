const Exchange = artifacts.require("./exchange/Exchange.sol");

module.exports = async (deployer) => {
    await deployer.deploy(Exchange);
};

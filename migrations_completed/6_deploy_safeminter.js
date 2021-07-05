const safeMinter = artifacts.require("./safeUtils/safeMinter.sol");

module.exports = async (deployer) => {
    await deployer.deploy(safeMinter, "0xb2AA4a5DF3641D42e72D7F07a40292794dfD07a0");
}
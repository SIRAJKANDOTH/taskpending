const safeUtils = artifacts.require("./safeUtils/safeUtils.sol");

module.exports = async (deployer) => {
    await deployer.deploy(safeUtils);
}
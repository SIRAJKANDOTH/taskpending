const safeUtils = artifacts.require("SafeUtils.sol");

module.exports = async (deployer) => {
  await deployer.deploy(safeUtils);
};

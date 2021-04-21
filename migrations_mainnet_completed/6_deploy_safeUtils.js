const SafeUtils = artifacts.require("./safeUtils/SafeUtils.sol");

module.exports = async (deployer) => {

	
	await deployer.deploy(SafeUtils);
	
};

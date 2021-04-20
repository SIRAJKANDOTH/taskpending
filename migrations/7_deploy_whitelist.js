
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");


module.exports = async (deployer) => {

	await deployer.deploy(Whitelist);

	
};

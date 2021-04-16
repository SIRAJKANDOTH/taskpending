const Whitelist = artifacts.require("./whitelist/Whitelist.sol");


module.exports = async (deployer) => {
  	await deployer.deploy(Whitelist);
	const whitelist = await Whitelist.deployed();
    console.log('whitelist deployed. Address = ',whitelist.address)
};
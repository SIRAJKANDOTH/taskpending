var GnosisSafe = artifacts.require("./GnosisSafe.sol");
var Whitelist = artifacts.require("./whitelist/Whitelist.sol");
var APContract = artifacts.require("./aps/APContract.sol");
var ProxyFactory = artifacts.require("./proxies/GnosisSafeProxyFactory.sol");

module.exports = async (deployer) => {
	await deployer.deploy(GnosisSafe);
	const gnosisSafeMasterCopy = await GnosisSafe.deployed();

	await deployer.deploy(Whitelist);
	const whitelist = await Whitelist.deployed();

	await deployer.deploy(
		APContract,
		gnosisSafeMasterCopy.address,
		whitelist.address
	);
	const apContract = await APContract.deployed();

	await deployer.deploy(
		ProxyFactory,
		gnosisSafeMasterCopy.address,
		apContract.address
	);
	const proxyFactory = await ProxyFactory.deployed();

	await apContract.addProxyFactory(proxyFactory.address);
};

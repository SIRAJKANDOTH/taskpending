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
	await apContract.addAsset("TUSD","Tether USD","0x6f7454cba97fffe10e053187f23925a86f5c20c4","0x7bee4c1408c6461ee35a9027ea6007e7d1764036")
	await apContract.addAsset("DAI","DAI Coin","0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF","0x95b58a6bff3d14b7db2f5cb5f0ad413dc2940658")
	await apContract.addAsset("USDC","USD Coin","0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB","0x7d66cde53cc0a169cae32712fc48934e610aef14")
	await apContract.addAsset("LINK","LINK Coin","0xd8bD0a1cB028a31AA859A21A3758685a95dE4623","0x01be23585060835e02b77ef475b0cc51aa1e0709")
	await apContract.addAsset("BAT","Basic Attention Token","0x031dB56e01f82f20803059331DC6bEe9b17F7fC9","0x2fa6a0728a63115e6fc1eb8496ea94e86b8cdf7b")
	await apContract.addAsset("BNB","Binance Coin","0xcf0f51ca2cDAecb464eeE4227f5295F2384F84ED","0x030b0a08ecadde5ac33859a48d87416946c966a1")
	await apContract.addAsset("fnx","FinanceX token","0xcf74110A02b1D391B27cE37364ABc3b279B1d9D1","0xd729a77e319e059b4467c402e173c552e63a6c55")

	await apContract.addProtocol("yearn Curve.fi GUSD/3Crv","crvGUSD","0x95b58a6bff3d14b7db2f5cb5f0ad413dc2940658")
	await apContract.addProtocol("yearn Curve.fi MUSD/3Crv","crvMUSD","0x7d66cde53cc0a169cae32712fc48934e610aef14")
	await apContract.addProtocol("yearn Curve.fi cDAI/cUSDC","crvCOMP","0xfb1d709cb959ac0ea14cad0927eabc7832e65058")
	await apContract.addProtocol("yearn yearn.finance","YFI","0x01be23585060835e02b77ef475b0cc51aa1e0709")
	await apContract.addProtocol("HEGIC yVault","HEGIC","0x2fa6a0728a63115e6fc1eb8496ea94e86b8cdf7b")

	await apContract.addStrategy("Yearn it All", "0x6f7454cba97fffe10e053187f23925a86f5c20c4",["0x95b58a6bff3d14b7db2f5cb5f0ad413dc2940658", "0x7d66cde53cc0a169cae32712fc48934e610aef14"])
	await apContract.addStrategy("Smart Deposit", "0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF",["0x95b58a6bff3d14b7db2f5cb5f0ad413dc2940658","0x7d66cde53cc0a169cae32712fc48934e610aef14"])
	await apContract.addStrategy("Smart Withdraw", "0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB",["0x95b58a6bff3d14b7db2f5cb5f0ad413dc2940658","0x7d66cde53cc0a169cae32712fc48934e610aef14"])

};

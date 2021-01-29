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
	await apContract.addAsset("TUSD","Tether USD","0x6f7454cba97fffe10e053187f23925a86f5c20c4","0xdac17f958d2ee523a2206206994597c13d831ec7")
	await apContract.addAsset("DAI","DAI Coin","0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF","0x6b175474e89094c44da98b954eedeac495271d0f")
	await apContract.addAsset("USDC","USD Coin","0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB","0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
	await apContract.addAsset("LINK","LINK Coin","0xd8bD0a1cB028a31AA859A21A3758685a95dE4623","0x01be23585060835e02b77ef475b0cc51aa1e0709")

	await apContract.addProtocol("yearn Curve.fi GUSD/3Crv","crvGUSD","0xcC7E70A958917cCe67B4B87a8C30E6297451aE98")
	await apContract.addProtocol("yearn Curve.fi MUSD/3Crv","crvMUSD","0x0FCDAeDFb8A7DfDa2e9838564c5A1665d856AFDF")
	await apContract.addProtocol("yearn Curve.fi cDAI/cUSDC","crvCOMP","0x629c759D1E83eFbF63d84eb3868B564d9521C129")
	await apContract.addProtocol("yearn yearn.finance","YFI","0xBA2E7Fed597fd0E3e70f5130BcDbbFE06bB94fe1")
	await apContract.addProtocol("HEGIC yVault","HEGIC","0xe11ba472F74869176652C35D30dB89854b5ae84D")

	await apContract.addStrategy("Yearn it All", "0x6f7454cba97fffe10e053187f23925a86f5c20c4",[])
	await apContract.addStrategy("Smart Deposit", "0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF",[])
	await apContract.addStrategy("Smart Withdraw", "0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB",[])

};

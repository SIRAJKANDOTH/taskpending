var GnosisSafe = artifacts.require("./GnosisSafe.sol");
var Whitelist = artifacts.require("./whitelist/Whitelist.sol");
var APContract = artifacts.require("./aps/APContract.sol");
var PriceModule = artifacts.require("./price/PriceModule.sol");
var ProxyFactory = artifacts.require("./proxies/GnosisSafeProxyFactory.sol");
var YearnItAll = artifacts.require("./strategies/YearnItAll.sol");

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

	await deployer.deploy(PriceModule, apContract.address);
	const priceModule = await PriceModule.deployed();

	await apContract.setPriceModule(priceModule.address);

	await deployer.deploy(
		ProxyFactory,
		gnosisSafeMasterCopy.address,
		apContract.address
	);
	const proxyFactory = await ProxyFactory.deployed();

	await apContract.addProxyFactory(proxyFactory.address);

	await deployer.deploy(YearnItAll, apContract.address, [
		"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
		"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
		"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
	]);
	const yearnItAll = await YearnItAll.deployed();

	//adding assets
	await apContract.addAsset(
		"DAI",
		"DAI Coin",
		"0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF",
		"0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea"
	);
	await apContract.addAsset(
		"USDC",
		"USD Coin",
		"0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB",
		"0x4dbcdf9b62e891a7cec5a2568c3f4faf9e8abe2b"
	);
	await apContract.addAsset(
		"LINK",
		"LINK Coin",
		"0xd8bD0a1cB028a31AA859A21A3758685a95dE4623",
		"0x01be23585060835e02b77ef475b0cc51aa1e0709"
	);
	await apContract.addAsset(
		"BAT",
		"Basic Attention Token",
		"0x031dB56e01f82f20803059331DC6bEe9b17F7fC9",
		"0xbf7a7169562078c96f0ec1a8afd6ae50f12e5a99"
	);
	await apContract.addAsset(
		"BNB",
		"Binance Coin",
		"0xcf0f51ca2cDAecb464eeE4227f5295F2384F84ED",
		"0x030b0a08ecadde5ac33859a48d87416946c966a1"
	);
	await apContract.addAsset(
		"fnx",
		"FinanceX token",
		"0xcf74110A02b1D391B27cE37364ABc3b279B1d9D1",
		"0xd729a77e319e059b4467c402e173c552e63a6c55"
	);

	//adding protocols in the assets for feed address

	await apContract.addAsset(
		"yearn Curve.fi crvCOMP",
		"crvCOMP",
		"0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF",
		"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8"
	);
	await apContract.addAsset(
		"yearn Curve.fi GUSD/3Crv",
		"crvGUSD",
		"0xd8bD0a1cB028a31AA859A21A3758685a95dE4623",
		"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e"
	);
	await apContract.addAsset(
		"yearn Curve.fi MUSD/3Crv",
		"crvMUSD",
		"0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB",
		"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B"
	);

	//adding protocols
	await apContract.addProtocol(
		"yearn Curve.fi crvCOMP",
		"crvCOMP",
		"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8"
	);
	await apContract.addProtocol(
		"yearn Curve.fi GUSD/3Crv",
		"crvGUSD",
		"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e"
	);
	await apContract.addProtocol(
		"yearn Curve.fi MUSD/3Crv",
		"crvMUSD",
		"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B"
	);

	await apContract.addStrategy("Yearn it All", yearnItAll.address, [
		"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
		"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
		"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
	]);

	await apContract.addStrategy(
		"Smart Deposit",
		"0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF",
		[
			"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
			"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
			"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
		]
	);
	await apContract.addStrategy(
		"Smart Withdraw",
		"0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB",
		[
			"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
			"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
			"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
		]
	);
};

const utils = require("./utils/general");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const PriceModule = artifacts.require("./price/PriceModule.sol");
const ProxyFactory = artifacts.require("./YieldsterVaultProxyFactory.sol");
var YearnItAll = artifacts.require("./strategies/YearnItAll.sol");
const YRToken = artifacts.require("./yrToken.sol");
const AishToken = artifacts.require("./aishToken.sol");

function token(n) {
	return web3.utils.toWei(n, "ether");
}

contract(" Deposit", function (accounts) {
	let newYieldsterVault;
	let newYieldsterVaultData;
	let newYieldsterVaultAddress;
	let yieldsterVaultMasterCopy;
	let apContract;
	let whitelist;
	let priceModule;
	let proxyFactory;
	let yrtToken;
	let aishToken;
	let yearnItAll;

	beforeEach(async function () {
		whitelist = await Whitelist.new();
		yieldsterVaultMasterCopy = await utils.deployContract(
			"deploying Yieldster Vault Mastercopy",
			YieldsterVault
		);
		apContract = await APContract.new(
			yieldsterVaultMasterCopy.address,
			whitelist.address
		);

		priceModule = await PriceModule.new(apContract.address);

		await apContract.setPriceModule(priceModule.address);

		proxyFactory = await ProxyFactory.new(
			yieldsterVaultMasterCopy.address,
			apContract.address
		);

		await apContract.addProxyFactory(proxyFactory.address);

		yrtToken = await YRToken.new(token("100000000"));
		aishToken = await AishToken.new(token("100000000"));

		yearnItAll = await YearnItAll.new(apContract.address, [
			"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
			"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
			"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
		]);
		await apContract.addAsset(
			"YRT",
			"YRT Token",
			"0x6f7454cba97fffe10e053187f23925a86f5c20c4",
			yrtToken.address
		);
		await apContract.addAsset(
			"AISH",
			"AISH Token",
			"0x6f7454cba97fffe10e053187f23925a86f5c20c4",
			aishToken.address
		);

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
	});

	it("should add vault to APS", async () => {
		newYieldsterVaultData = await yieldsterVaultMasterCopy.contract.methods
			.setup(
				"Liva One",
				"Liva",
				"LV",
				accounts[0],
				accounts[1],
				apContract.address,
				[]
			)
			.encodeABI();

		newYieldsterVault = await utils.getParamFromTxEvent(
			await proxyFactory.createProxy(newYieldsterVaultData),
			"ProxyCreation",
			"proxy",
			proxyFactory.address,
			YieldsterVault,
			"create Yieldster Vault"
		);

		console.log(
			"vault owner",
			await newYieldsterVault.owner(),
			"other address",
			accounts[0]
		);

		await newYieldsterVault.registerVaultWithAPS(
			[
				"0x4dbcdf9b62e891a7cec5a2568c3f4faf9e8abe2b",
				"0x01be23585060835e02b77ef475b0cc51aa1e0709",
				yrtToken.address,
				aishToken.address,
			],
			[
				"0x4dbcdf9b62e891a7cec5a2568c3f4faf9e8abe2b",
				"0x01be23585060835e02b77ef475b0cc51aa1e0709",
				yrtToken.address,
				aishToken.address,
			]
		);

		console.log("vault Name", await newYieldsterVault.vaultName());
		assert.equal(await newYieldsterVault.vaultName(), "Liva One", "Names match");

		let vaultNAVInitial = await newYieldsterVault.getVaultNAV();
		console.log("vault NAV Initial", vaultNAVInitial.toString());

		let vaultTokenValueInitial = await newYieldsterVault.tokenValueInUSD();
		console.log("token value usd Initial", vaultTokenValueInitial.toString());

		await newYieldsterVault.setVaultStrategyAndProtocol(
			yearnItAll.address,
			[
				"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
				"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
				"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
			],
			[]
		);

		await newYieldsterVault.setVaultActiveStrategy(yearnItAll.address);

		console.log(
			"active strategy given ",
			yearnItAll.address,
			" set ",
			await newYieldsterVault.getVaultActiveStrategy()
		);

		await newYieldsterVault.setStrategyActiveProtocol(
			"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8"
		);
	});
});

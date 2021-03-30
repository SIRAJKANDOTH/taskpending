const utils = require("./utils/general");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const PriceModule = artifacts.require("./price/PriceModule.sol");
const ProxyFactory = artifacts.require("./YieldsterVaultProxyFactory.sol");
const YRToken = artifacts.require("./yrToken.sol");
const AishToken = artifacts.require("./aishToken.sol");
const ManagementFee = artifacts.require(
	"./delegateContracts/ManagementFee.sol"
);
const YearnItAll = artifacts.require("./strategies/YearnItAll.sol");
const LivaOne = artifacts.require("./strategies/LivaOne.sol");
const YearnItAllMinter = artifacts.require("./strategies/YearnItAllMinter.sol");
const LivaOneMinter = artifacts.require("./strategies/LivaOneMinter.sol");
const HexUtils = artifacts.require("./utils/HexUtils.sol");

const StockDeposit = artifacts.require(
	"./smartStrategies/deposit/StockDeposit.sol"
);
const StockWithdraw = artifacts.require(
	"./smartStrategies/deposit/StockWithdraw.sol"
);
const Exchange = artifacts.require("./exchange/Exchange.sol");

function token(n) {
	return web3.utils.toWei(n, "ether");
}

contract(" Deposit", function (accounts) {
	let newYieldsterVault;
	let newYieldsterVaultData;
	let yieldsterVaultMasterCopy;
	let apContract;
	let whitelist;
	let priceModule;
	let proxyFactory;
	let yrtToken;
	let aishToken;
	let groupId;
	let strategyMinter;
	let managementFee;
	let stockDeposit;
	let stockWithdraw;
	let exchange;
	let hexUtils;

	beforeEach(async function () {
		whitelist = await Whitelist.new();
		hexUtils = await HexUtils.new();
		managementFee = await ManagementFee.new();
		stockDeposit = await StockDeposit.new();
		stockWithdraw = await StockWithdraw.new();
		exchange = await Exchange.new();

		yieldsterVaultMasterCopy = await utils.deployContract(
			"deploying Yieldster Vault Mastercopy",
			YieldsterVault
		);
		apContract = await APContract.new(
			yieldsterVaultMasterCopy.address,
			whitelist.address,
			managementFee.address,
			hexUtils.address
		);

		let groupHash = await whitelist.createGroup(accounts[1]);
		groupId = (await groupHash.logs[0].args["1"]).toString();

		console.log(
			"Is whitelisted == ",
			await whitelist.isMember(groupId, accounts[1])
		);

		priceModule = await PriceModule.new(apContract.address);

		await apContract.setPriceModule(priceModule.address);

		await apContract.setYieldsterExchange(exchange.address);

		await apContract.setStockDepositWithdraw(
			stockDeposit.address,
			stockWithdraw.address
		);

		proxyFactory = await ProxyFactory.new(
			yieldsterVaultMasterCopy.address,
			apContract.address
		);
		yrtToken = await YRToken.new(token("100000000"));
		aishToken = await AishToken.new(token("100000000"));

		await yrtToken.transfer(accounts[1], token("500"), { from: accounts[0] });
		await yrtToken.transfer(accounts[2], token("500"), { from: accounts[0] });
		await yrtToken.transfer(accounts[3], token("500"), { from: accounts[0] });
		await aishToken.transfer(accounts[1], token("500"), { from: accounts[0] });
		await aishToken.transfer(accounts[2], token("500"), { from: accounts[0] });
		await aishToken.transfer(accounts[3], token("500"), { from: accounts[0] });

		await apContract.addProxyFactory(proxyFactory.address);

		await apContract.addProxyFactory(proxyFactory.address);

		await apContract.addAsset(
			"YRT",
			"YRT Token",
			"0xd8bD0a1cB028a31AA859A21A3758685a95dE4623",
			yrtToken.address
		);
		await apContract.addAsset(
			"AISH",
			"AISH Token",
			"0x6f7454cba97fffe10e053187f23925a86f5c20c4",
			aishToken.address
		);
		await apContract.addAsset(
			"TUSD",
			"Tether USD",
			"0x6f7454cba97fffe10e053187f23925a86f5c20c4",
			"0xd9ba894e0097f8cc2bbc9d24d308b98e36dc6d02"
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

		//Deploying Yearn It All strategy
		const yearnItAll = await YearnItAll.new(apContract.address, [
			"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
			"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
			"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
		]);
		const yearnItAllMinter = await YearnItAllMinter.new(
			apContract.address,
			yearnItAll.address
		);

		//Deploying Liva One strategy
		const livaOne = await LivaOne.new(apContract.address, [
			"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
			"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
			"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
		]);
		const livaOneMinter = await LivaOneMinter.new(
			apContract.address,
			livaOne.address
		);
		await apContract.addStrategy(
			"Yearn it All",
			yearnItAll.address,
			[
				"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
				"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
				"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
			],
			yearnItAllMinter.address,
			"0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0"
		);
		await apContract.addStrategy(
			"Liva One",
			livaOne.address,
			[
				"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
				"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
				"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
			],
			livaOneMinter.address,
			"0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0"
		);
	});

	it("should add Vault to APS", async () => {
		newYieldsterVaultData = await yieldsterVaultMasterCopy.contract.methods
			.setup(
				"Liva One",
				"Liva",
				"LV",
				accounts[0],
				accounts[1],
				apContract.address,
				[groupId]
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
			"Vault owner",
			await newYieldsterVault.owner(),
			"other address",
			accounts[0]
		);

		await newYieldsterVault.registerVaultWithAPS();
		await newYieldsterVault.setVaultAssets(
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
			],
			[],
			[]
		);
		console.log("YRT TOken", yrtToken.address);

		console.log("Vault Name", await newYieldsterVault.vaultName());
		assert.equal(
			await newYieldsterVault.vaultName(),
			"Liva One",
			"Names match"
		);

		assert.ok(newYieldsterVault.address);
		let VaultNAVInitial = await newYieldsterVault.getVaultNAV();
		console.log("Vault NAV Initial", VaultNAVInitial.toString());

		let vaultTokenValueInitial = await newYieldsterVault.tokenValueInUSD();
		console.log("token value usd Initial", vaultTokenValueInitial.toString());

		console.log("-----------deposit----------------");

		await yrtToken.approve(newYieldsterVault.address, token("100"), {
			from: accounts[1],
		});

		await newYieldsterVault.deposit(yrtToken.address, token("1"), {
			from: accounts[1],
		});
		await aishToken.approve(newYieldsterVault.address, token("100"), {
			from: accounts[1],
		});

		// await aishToken.approve(newYieldsterVault.address, token("100"), {
		// 	from: accounts[2],
		// });

		// await newYieldsterVault.deposit(aishToken.address, token("2"), {
		// 	from: accounts[2],
		// });
		// await yrtToken.approve(newYieldsterVault.address, token("100"), {
		// 	from: accounts[2],
		// });
		// await newYieldsterVault.deposit(yrtToken.address, token("8"), {
		// 	from: accounts[2],
		// });
		// await yrtToken.approve(newYieldsterVault.address, token("100"), {
		// 	from: accounts[3],
		// });
		// await newYieldsterVault.deposit(yrtToken.address, token("18"), {
		// 	from: accounts[3],
		// });

		let yrtBalance = await yrtToken.balanceOf(newYieldsterVault.address);
		console.log(
			"Vault YRT Balance",
			web3.utils.fromWei(yrtBalance.toString(), "ether")
		);

		let aishBalance = await aishToken.balanceOf(newYieldsterVault.address);
		console.log(
			"Vault AISH Balance",
			web3.utils.fromWei(aishBalance.toString(), "ether")
		);

		let investor1VaultBalance = await newYieldsterVault.balanceOf(accounts[1]);
		let investor2VaultBalance = await newYieldsterVault.balanceOf(accounts[2]);
		// let investor3VaultBalance = await newYieldsterVault.balanceOf(accounts[3]);
		console.log(
			"Vault Token investor1 balance",
			web3.utils.fromWei(investor1VaultBalance.toString(), "ether")
		);
		console.log(
			"Vault Token investor2 balance",
			web3.utils.fromWei(investor2VaultBalance.toString(), "ether")
		);
		// console.log(
		// 	"Vault Token investor3 balance",
		// 	web3.utils.fromWei(investor3VaultBalance.toString(), "ether")
		// );
		let vaultNAV = await newYieldsterVault.getVaultNAV();
		console.log("Vault NAV", vaultNAV.toString());
		// let deleigateresult= await newYieldsterVault.managementFeeCleanUp(managementFee.address);
		// console.log("Vault NAV wth delegate", deleigateresult);
		// console.log("Vault NAV wth delegate", (await newYieldsterVault.test()).toString());
		console.log(
			"Vault NAV from WEI",
			web3.utils.fromWei(vaultNAV.toString(), "ether")
		);
		let vaultTokenValue = await newYieldsterVault.tokenValueInUSD();
		console.log(
			"token value usd ",
			web3.utils.fromWei(vaultTokenValue.toString(), "ether")
		);

		let totalSupply = await newYieldsterVault.totalSupply();
		console.log(
			"Vault total supply ",
			web3.utils.fromWei(totalSupply.toString(), "ether")
		);

		// let yrt = await apContract.getUSDPrice(yrtToken.address);
		// console.log(
		// 	"yrt values",
		// 	yrt[0].toString(),
		// 	"-",
		// 	yrt[1].toString(),
		// 	"-",
		// 	yrt[2].toString()
		// );

		// investor1VaultBalance = await newYieldsterVault.balanceOf(accounts[1]);
		// console.log(
		// 	"Vault Token investor1 balance",
		// 	web3.utils.fromWei(investor1VaultBalance.toString(), "ether")
		// );
		let investor1YrtBalance = await yrtToken.balanceOf(accounts[1]);
		console.log(
			"Investor 1 YRT before withdrawal",
			web3.utils.fromWei(investor1YrtBalance.toString(), "ether")
		);

		let investor1aishBalance = await aishToken.balanceOf(accounts[1]);
		console.log(
			"Investor 1 AISH before withdrawal",
			web3.utils.fromWei(investor1aishBalance.toString(), "ether")
		);

		console.log("------------withdraw-----------");

		await newYieldsterVault.withdraw(token("1"), {
			from: accounts[1],
		});
		// await newYieldsterVault.withdraw(token("8"), {
		// 	from: accounts[2],
		// });
		// await newYieldsterVault.withdraw(token("18"), {
		// 	from: accounts[3],
		// });
		investor1VaultBalance = await newYieldsterVault.balanceOf(accounts[1]);
		console.log(
			"Vault Token investor1 balance",
			web3.utils.fromWei(investor1VaultBalance.toString(), "ether")
		);

		investor1YrtBalance = await yrtToken.balanceOf(accounts[1]);
		console.log(
			"Investor 1 YRT after withdrawal",
			web3.utils.fromWei(investor1YrtBalance.toString(), "ether")
		);

		investor1aishBalance = await aishToken.balanceOf(accounts[1]);
		console.log(
			"Investor 1 AISH after withdrawal",
			web3.utils.fromWei(investor1aishBalance.toString(), "ether")
		);

		yrtBalance = await yrtToken.balanceOf(newYieldsterVault.address);
		console.log(
			"Vault YRT Balance",
			web3.utils.fromWei(yrtBalance.toString(), "ether")
		);

		aishBalance = await aishToken.balanceOf(newYieldsterVault.address);
		console.log(
			"Vault AISH Balance",
			web3.utils.fromWei(aishBalance.toString(), "ether")
		);

		vaultNAV = await newYieldsterVault.getVaultNAV();
		console.log("Vault NAV", vaultNAV.toString());
		console.log(
			"Vault NAV from WEI",
			web3.utils.fromWei(vaultNAV.toString(), "ether")
		);
		vaultTokenValue = await newYieldsterVault.tokenValueInUSD();
		console.log(
			"token value usd ",
			web3.utils.fromWei(vaultTokenValue.toString(), "ether")
		);

		totalSupply = await newYieldsterVault.totalSupply();
		console.log(
			"Vault total supply ",
			web3.utils.fromWei(totalSupply.toString(), "ether")
		);

		// await newYieldsterVault.deposit(yrtToken.address, token("10"), {
		// 	from: accounts[1],
		// });

		// await newYieldsterVault.enableEmergencyBreak();
		// await newYieldsterVault.disableEmergencyBreak();
		// await newYieldsterVault.deposit(yrtToken.address, token("1"), {
		// 	from: accounts[1],
		// });

		// console.log(
		// 	"emergency vault YRT",
		// 	web3.utils.fromWei(await yrtToken.balanceOf(accounts[0]), "ether")
		// );

		// await newYieldsterVault.enableEmergencyExit();

		// console.log(
		// 	"emergency vault YRT",
		// 	web3.utils.fromWei(await yrtToken.balanceOf(accounts[0]), "ether")
		// );
		// await newYieldsterVault.deposit(yrtToken.address, token("10"), {
		// 	from: accounts[1],
		// });

		// await newYieldsterVault.withdraw(yrtToken.address, token("2"),{from:accounts[2]});
		// investor2YrtBalance = await yrtToken.balanceOf(accounts[2]);
		// console.log(
		// 	"Investor 2 after withdrawal",
		// 	web3.utils.fromWei(investor2YrtBalance.toString(), "ether")
		// );

		console.log("After direct deposit");

		await yrtToken.transfer(newYieldsterVault.address, token("100"), {
			from: accounts[1],
		});

		yrtBalance = await yrtToken.balanceOf(newYieldsterVault.address);
		console.log(
			"Vault YRT Balance",
			web3.utils.fromWei(yrtBalance.toString(), "ether")
		);

		aishBalance = await aishToken.balanceOf(newYieldsterVault.address);
		console.log(
			"Vault AISH Balance",
			web3.utils.fromWei(aishBalance.toString(), "ether")
		);

		vaultNAV = await newYieldsterVault.getVaultNAV();
		console.log("Vault NAV", vaultNAV.toString());
		console.log(
			"Vault NAV from WEI",
			web3.utils.fromWei(vaultNAV.toString(), "ether")
		);
		vaultTokenValue = await newYieldsterVault.tokenValueInUSD();
		console.log(
			"token value usd ",
			web3.utils.fromWei(vaultTokenValue.toString(), "ether")
		);

		totalSupply = await newYieldsterVault.totalSupply();
		console.log(
			"Vault total supply ",
			web3.utils.fromWei(totalSupply.toString(), "ether")
		);
	});
});

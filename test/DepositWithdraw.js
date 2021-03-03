const utils = require("./utils/general");
const GnosisSafe = artifacts.require("./GnosisSafe.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const PriceModule = artifacts.require("./price/PriceModule.sol");
const ProxyFactory = artifacts.require("./GnosisSafeProxyFactory.sol");
const YRToken = artifacts.require("./yrToken.sol");
const AishToken = artifacts.require("./aishToken.sol");
const ManagementFee=artifacts.require("./delegateContracts/ManagementFee.sol");

function token(n) {
	return web3.utils.toWei(n, "ether");
}

contract(" Deposit", function (accounts) {
	let newGnosisSafe;
	let newGnosisSafeData;
	let newGnosisSafeAddress;
	let gnosisSafeMasterCopy;
	let apContract;
	let whitelist;
	let priceModule;
	let proxyFactory;
	let yrtToken;
	let aishToken;

	beforeEach(async function () {
		whitelist = await Whitelist.new();
		managementFee = await ManagementFee.new();
		gnosisSafeMasterCopy = await utils.deployContract(
			"deploying Gnosis Safe Mastercopy",
			GnosisSafe
		);
		apContract = await APContract.new(
			gnosisSafeMasterCopy.address,
			whitelist.address
		);

		priceModule = await PriceModule.new(apContract.address);

		await apContract.setPriceModule(priceModule.address);

		proxyFactory = await ProxyFactory.new(
			gnosisSafeMasterCopy.address,
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
			"yearn Curve.fi GUSD/3Crv",
			"crvGUSD",
			"0x95b58a6bff3d14b7db2f5cb5f0ad413dc2940658"
		);
		await apContract.addProtocol(
			"yearn Curve.fi MUSD/3Crv",
			"crvMUSD",
			"0x7d66cde53cc0a169cae32712fc48934e610aef14"
		);
		await apContract.addProtocol(
			"yearn Curve.fi cDAI/cUSDC",
			"crvCOMP",
			"0xfb1d709cb959ac0ea14cad0927eabc7832e65058"
		);
		await apContract.addProtocol(
			"yearn yearn.finance",
			"YFI",
			"0x01be23585060835e02b77ef475b0cc51aa1e0709"
		);
		await apContract.addProtocol(
			"HEGIC yVault",
			"HEGIC",
			"0x2fa6a0728a63115e6fc1eb8496ea94e86b8cdf7b"
		);

		await apContract.addStrategy(
			"Yearn it All",
			"0x6f7454cba97fffe10e053187f23925a86f5c20c4",
			[
				"0x95b58a6bff3d14b7db2f5cb5f0ad413dc2940658",
				"0x7d66cde53cc0a169cae32712fc48934e610aef14",
			]
		);
		await apContract.addStrategy(
			"Smart Deposit",
			"0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF",
			[
				"0x95b58a6bff3d14b7db2f5cb5f0ad413dc2940658",
				"0x7d66cde53cc0a169cae32712fc48934e610aef14",
			]
		);
		await apContract.addStrategy(
			"Smart Withdraw",
			"0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB",
			[
				"0x95b58a6bff3d14b7db2f5cb5f0ad413dc2940658",
				"0x7d66cde53cc0a169cae32712fc48934e610aef14",
			]
		);
	});

	it("should add safe to APS", async () => {
		newGnosisSafeData = await gnosisSafeMasterCopy.contract.methods
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

		newGnosisSafe = await utils.getParamFromTxEvent(
			await proxyFactory.createProxy(newGnosisSafeData),
			"ProxyCreation",
			"proxy",
			proxyFactory.address,
			GnosisSafe,
			"create Gnosis Safe"
		);

		console.log(
			"safe owner",
			await newGnosisSafe.owner(),
			"other address",
			accounts[0]
		);

		await newGnosisSafe.registerVaultWithAPS(
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
		console.log("YRT TOken", yrtToken.address);

		console.log("Safe Name", await newGnosisSafe.vaultName());
		assert.equal(await newGnosisSafe.vaultName(), "Liva One", "Names match");

		assert.ok(newGnosisSafe.address);
		let safeNAVInitial = await newGnosisSafe.getVaultNAV();
		console.log("Safe NAV Initial", safeNAVInitial.toString());


		let safeTokenValueInitial = await newGnosisSafe.tokenValueInUSD();
		console.log("token value usd Initial", safeTokenValueInitial.toString());

		console.log("-----------deposit----------------");

		await yrtToken.approve(newGnosisSafe.address, token("100"), {
			from: accounts[1],
		});
		await newGnosisSafe.deposit(yrtToken.address, token("1"), {
			from: accounts[1],
		});
		await aishToken.approve(newGnosisSafe.address, token("100"), {
			from: accounts[1],
		});
		// await newGnosisSafe.deposit(aishToken.address, token("2"), {
		// 	from: accounts[1],
		// });
		// await yrtToken.approve(newGnosisSafe.address, token("100"), {
		// 	from: accounts[2],
		// });
		// await newGnosisSafe.deposit(yrtToken.address, token("8"), {
		// 	from: accounts[2],
		// });
		// await yrtToken.approve(newGnosisSafe.address, token("100"), {
		// 	from: accounts[3],
		// });
		// await newGnosisSafe.deposit(yrtToken.address, token("18"), {
		// 	from: accounts[3],
		// });

		let yrtBalance = await yrtToken.balanceOf(newGnosisSafe.address);
		console.log(
			"Safe YRT Balance",
			web3.utils.fromWei(yrtBalance.toString(), "ether")
		);

		let aishBalance = await aishToken.balanceOf(newGnosisSafe.address);
		console.log(
			"Safe AISH Balance",
			web3.utils.fromWei(aishBalance.toString(), "ether")
		);

		let investor1SafeBalance = await newGnosisSafe.balanceOf(accounts[1]);
		// let investor2SafeBalance = await newGnosisSafe.balanceOf(accounts[2]);
		// let investor3SafeBalance = await newGnosisSafe.balanceOf(accounts[3]);
		console.log(
			"Safe Token investor1 balance",
			web3.utils.fromWei(investor1SafeBalance.toString(), "ether")
		);
		// console.log(
		// 	"Safe Token investor2 balance",
		// 	web3.utils.fromWei(investor2SafeBalance.toString(), "ether")
		// );
		// console.log(
		// 	"Safe Token investor3 balance",
		// 	web3.utils.fromWei(investor3SafeBalance.toString(), "ether")
		// );
		let safeNAV = await newGnosisSafe.getVaultNAV();
		console.log("Safe NAV", safeNAV.toString());
		let deleigateresult= await newGnosisSafe.managementFeeCleanUp(managementFee.address);
		console.log("Safe NAV wth delegate", deleigateresult);
		console.log("Safe NAV wth delegate", (await newGnosisSafe.test()).toString());
		console.log(
			"Safe NAV from WEI",
			web3.utils.fromWei(safeNAV.toString(), "ether")
		);
		let safeTokenValue = await newGnosisSafe.tokenValueInUSD();
		console.log("token value usd ", web3.utils.fromWei(safeTokenValue.toString(),"ether"));

		let totalSupply = await newGnosisSafe.totalSupply();
		console.log(
			"safe total supply ",
			web3.utils.fromWei(totalSupply.toString(), "ether")
		);

		let depositNAV = await newGnosisSafe.getDepositNAV(
			yrtToken.address,
			token("1")
		);
		console.log(
			"Deposit NAV",
			web3.utils.fromWei(depositNAV.toString(), "ether")
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

		// investor1SafeBalance = await newGnosisSafe.balanceOf(accounts[1]);
		// console.log(
		// 	"Safe Token investor1 balance",
		// 	web3.utils.fromWei(investor1SafeBalance.toString(), "ether")
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

		await newGnosisSafe.withdraw(token("1"), {
			from: accounts[1],
		});
		// await newGnosisSafe.withdraw(token("8"), {
		// 	from: accounts[2],
		// });
		// await newGnosisSafe.withdraw(token("18"), {
		// 	from: accounts[3],
		// });
		investor1SafeBalance = await newGnosisSafe.balanceOf(accounts[1]);
		console.log(
			"Safe Token investor1 balance",
			web3.utils.fromWei(investor1SafeBalance.toString(), "ether")
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

		yrtBalance = await yrtToken.balanceOf(newGnosisSafe.address);
		console.log(
			"Safe YRT Balance",
			web3.utils.fromWei(yrtBalance.toString(), "ether")
		);

		aishBalance = await aishToken.balanceOf(newGnosisSafe.address);
		console.log(
			"Safe AISH Balance",
			web3.utils.fromWei(aishBalance.toString(), "ether")
		);

		safeNAV = await newGnosisSafe.getVaultNAV();
		console.log("Safe NAV", safeNAV.toString());
		console.log(
			"Safe NAV from WEI",
			web3.utils.fromWei(safeNAV.toString(), "ether")
		);
		safeTokenValue = await newGnosisSafe.tokenValueInUSD();
		console.log("token value usd ", web3.utils.fromWei(safeTokenValue.toString(),"ether"));

		totalSupply = await newGnosisSafe.totalSupply();
		console.log(
			"safe total supply ",
			web3.utils.fromWei(totalSupply.toString(), "ether")
		);

		depositNAV = await newGnosisSafe.getDepositNAV(
			yrtToken.address,
			token("1")
		);
		console.log(
			"Deposit NAV",
			web3.utils.fromWei(depositNAV.toString(), "ether")
		);

		// await newGnosisSafe.withdraw(yrtToken.address, token("2"),{from:accounts[2]});
		// investor2YrtBalance = await yrtToken.balanceOf(accounts[2]);
		// console.log(
		// 	"Investor 2 after withdrawal",
		// 	web3.utils.fromWei(investor2YrtBalance.toString(), "ether")
		// );

		console.log("After direct deposit")

		await yrtToken.transfer(newGnosisSafe.address, token("100"), {
			from: accounts[1],
		});

		yrtBalance = await yrtToken.balanceOf(newGnosisSafe.address);
		console.log(
			"Safe YRT Balance",
			web3.utils.fromWei(yrtBalance.toString(), "ether")
		);

		aishBalance = await aishToken.balanceOf(newGnosisSafe.address);
		console.log(
			"Safe AISH Balance",
			web3.utils.fromWei(aishBalance.toString(), "ether")
		);

		safeNAV = await newGnosisSafe.getVaultNAV();
		console.log("Safe NAV", safeNAV.toString());
		console.log(
			"Safe NAV from WEI",
			web3.utils.fromWei(safeNAV.toString(), "ether")
		);
		safeTokenValue = await newGnosisSafe.tokenValueInUSD();
		console.log("token value usd ", web3.utils.fromWei(safeTokenValue.toString(),"ether"));

		totalSupply = await newGnosisSafe.totalSupply();
		console.log(
			"safe total supply ",
			web3.utils.fromWei(totalSupply.toString(), "ether")
		);
	});
});

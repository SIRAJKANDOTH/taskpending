const utils = require("./utils/general");
const GnosisSafe = artifacts.require("./GnosisSafe.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const ProxyFactory = artifacts.require("./GnosisSafeProxyFactory.sol");
const YRToken = artifacts.require("./yrToken.sol");

contract(" Deposit", function (accounts) {
	let newGnosisSafe;
	let newGnosisSafeData;
	let newGnosisSafeAddress;
	let gnosisSafeMasterCopy;
	let apContract;
	let whitelist;
	let proxyFactory;
	let yrtToken;

	beforeEach(async function () {
		whitelist = await Whitelist.new();
		gnosisSafeMasterCopy = await utils.deployContract(
			"deploying Gnosis Safe Mastercopy",
			GnosisSafe
		);
		apContract = await APContract.new(
			gnosisSafeMasterCopy.address,
			whitelist.address
		);

		proxyFactory = await ProxyFactory.new(
			gnosisSafeMasterCopy.address,
			apContract.address
		);
		yrtToken = await YRToken.new("10000000000000");

		await apContract.addProxyFactory(proxyFactory.address);

		await apContract.addAsset(
			"TUSD",
			"Tether USD",
			"0x6f7454cba97fffe10e053187f23925a86f5c20c4",
			"0xdac17f958d2ee523a2206206994597c13d831ec7"
		);
		await apContract.addAsset(
			"DAI",
			"DAI Coin",
			"0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF",
			"0x6b175474e89094c44da98b954eedeac495271d0f"
		);
		await apContract.addAsset(
			"USDC",
			"USD Coin",
			"0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB",
			"0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
		);
		await apContract.addAsset(
			"LINK",
			"LINK Coin",
			"0xd8bD0a1cB028a31AA859A21A3758685a95dE4623",
			"0x01be23585060835e02b77ef475b0cc51aa1e0709"
		);

		await apContract.addProtocol(
			"yearn Curve.fi GUSD/3Crv",
			"crvGUSD",
			"0xcC7E70A958917cCe67B4B87a8C30E6297451aE98"
		);
		await apContract.addProtocol(
			"yearn Curve.fi MUSD/3Crv",
			"crvMUSD",
			"0x0FCDAeDFb8A7DfDa2e9838564c5A1665d856AFDF"
		);
		await apContract.addProtocol(
			"yearn Curve.fi cDAI/cUSDC",
			"crvCOMP",
			"0x629c759D1E83eFbF63d84eb3868B564d9521C129"
		);
		await apContract.addProtocol(
			"yearn yearn.finance",
			"YFI",
			"0xBA2E7Fed597fd0E3e70f5130BcDbbFE06bB94fe1"
		);
		await apContract.addProtocol(
			"HEGIC yVault",
			"HEGIC",
			"0xe11ba472F74869176652C35D30dB89854b5ae84D"
		);

		await apContract.addStrategy(
			"Yearn it All",
			"0x6f7454cba97fffe10e053187f23925a86f5c20c4",
			[]
		);
		await apContract.addStrategy(
			"Smart Deposit",
			"0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF",
			[]
		);
		await apContract.addStrategy(
			"Smart Withdraw",
			"0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB",
			[]
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
				["group 1", "group 2"]
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
			[accounts[3], accounts[4]],
			[accounts[3], accounts[4]],
			[accounts[5], accounts[6]]
		);

		console.log("Safe Name", await newGnosisSafe.vaultName());
		assert.equal(await newGnosisSafe.vaultName(), "Liva One", "Names match");

		assert.ok(newGnosisSafe.address);

		// apContract.VaultCreation((err, result) => {
		// 	if (err) console.log("error");
		// 	console.log(result);
		// 	newGnosisSafeAddress = result.args.vaultAddress;
		// });

		// await apContract.createVault();
		// console.log("Address from event", newGnosisSafeAddress);

		// assert.ok(newGnosisSafeAddress);

		// newGnosisSafe = await GnosisSafe.at(newGnosisSafeAddress);
		// await newGnosisSafe.setup(
		// 	// "Example Safe1",
		// 	"Token 1",
		// 	"TKN1",
		// 	// accounts[2],
		// 	apContract.address,
		// 	[accounts[3], accounts[4]],
		// 	[accounts[3], accounts[4]],
		// 	["Group 1", "Group 2"],
		// 	{ from: accounts[0] }
		// );

		// console.log(
		// 	"Safe in APS",
		// 	await apContract._isVaultPresent(newGnosisSafeAddress)
		// );
		// assert.equal(
		// 	await apContract.isAssetEnabledInVault(newGnosisSafeAddress, accounts[3]),

		// 	true,
		// 	"The asset is present"
		// );
		// assert.equal(
		// 	await apContract.isAssetEnabledInVault(
		// 		newGnosisSafeAddress,
		// 		"0x5091af48beb623b3da0a53f726db63e13ff91df9"
		// 	),

		// 	false,
		// 	"The asset is not present"
		// );

		// assert.equal(
		// 	await newGnosisSafe.name(),
		// 	"Token 1",
		// 	"name is correctly set for safe"
		// );
		// assert.equal(
		// 	await newGnosisSafe.symbol(),
		// 	"TKN1",
		// 	"symbol is correctly set for safe"
		// );

		// console.log("vault assets ", await apContract.vaults(newGnosisSafeAddress));
	});
});

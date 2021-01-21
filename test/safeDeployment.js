const utils = require("./utils/general");
const ProxyFactory = artifacts.require("./GnosisSafeProxyFactory.sol");
const GnosisSafe = artifacts.require("./GnosisSafe.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");

contract(" APContract", function (accounts) {
	let gnosisSafe;
	let gnosisSafeData;
	let proxyFactory;
	let gnosisSafeMasterCopy;
	let apContract;
	let whitelist;

	beforeEach(async function () {
		// Create Master Copies
		proxyFactory = await ProxyFactory.new();
		whitelist = await Whitelist.new();
		apContract = await APContract.new(whitelist.address);

		gnosisSafeMasterCopy = await utils.deployContract(
			"deploying Gnosis Safe Mastercopy",
			GnosisSafe
		);

		await apContract.addAsset("DEX", "DEX Coin", accounts[5], accounts[3]);
		await apContract.addAsset("DAI", "DAI Coin", accounts[5], accounts[4]);
		await apContract.addProtocol(
			"Protocol DEX",
			"Protocol DEX Coin",
			accounts[3]
		);
		await apContract.addProtocol(
			"Protocol DAI",
			"Protocol DAI Coin",
			accounts[4]
		);

		gnosisSafeData = await gnosisSafeMasterCopy.contract.methods
			.setup(
				"Example Safe1",
				"Token 1",
				"TKN1",
				accounts[2],
				apContract.address,
				[accounts[3], accounts[4]],
				whitelist.address
			)
			.encodeABI();
	});

	it("should add safe to APS", async () => {
		gnosisSafe = await utils.getParamFromTxEvent(
			await proxyFactory.createProxy(
				gnosisSafeMasterCopy.address,
				gnosisSafeData
			),
			"ProxyCreation",
			"proxy",
			proxyFactory.address,
			GnosisSafe,
			"create Gnosis Safe "
		);

		assert.ok(gnosisSafe.address);

		await apContract.addVault(
			gnosisSafe.address,
			[accounts[3], accounts[4]],
			[accounts[3], accounts[4]],
			accounts[2],
			[1434, 245]
		);

		console.log(
			"Safe in APS",
			await apContract._isVaultPresent(gnosisSafe.address)
		);
		assert.equal(
			await apContract.isAssetEnabledInVault(gnosisSafe.address, accounts[3]),

			true,
			"The asset is present"
		);
		assert.equal(
			await apContract.isAssetEnabledInVault(
				gnosisSafe.address,
				"0x5091af48beb623b3da0a53f726db63e13ff91df9"
			),

			false,
			"The asset is not present"
		);
	});
});

// contract("Gnosis Safe", function (accounts) {
// 	let gnosisSafe1;
// 	let gnosisSafe2;
// 	let gnosisSafeData1, gnosisSafeData2;
// 	let proxyFactory;
// 	let gnosisSafeMasterCopy;
// 	let apContract;
// 	let whitelist;

// 	beforeEach(async function () {
// 		// Create Master Copies
// 		proxyFactory = await ProxyFactory.new();
// 		whitelist = await Whitelist.new();
// 		apContract = await APContract.new(whitelist.address);

// 		gnosisSafeMasterCopy = await utils.deployContract(
// 			"deploying Gnosis Safe Mastercopy",
// 			GnosisSafe
// 		);

// 		await apContract.addAsset("DEX", "DEX Coin", accounts[5], accounts[3]);
// 		await apContract.addAsset("DAI", "DAI Coin", accounts[5], accounts[4]);

// 		gnosisSafeData1 = await gnosisSafeMasterCopy.contract.methods
// 			.setup(
// 				"Example Safe1",
// 				"Token 1",
// 				"TKN1",
// 				accounts[2],
// 				apContract.address,
// 				[accounts[3], accounts[4]],
// 				whitelist.address
// 			)
// 			.encodeABI();

// 		gnosisSafeData2 = await gnosisSafeMasterCopy.contract.methods
// 			.setup(
// 				"Example Safe2",
// 				"Token 2",
// 				"TKN2",
// 				accounts[2],
// 				apContract.address,
// 				[accounts[3], accounts[4]],
// 				whitelist.address
// 			)
// 			.encodeABI();
// 	});

// 	it("should create two safes", async () => {
// 		proxyFactory.ProxyCreation((err, result) => {
// 			if (err) console.log("error");
// 			console.log(result);
// 		});
// 		gnosisSafe1 = await utils.getParamFromTxEvent(
// 			await proxyFactory.createProxy(
// 				gnosisSafeMasterCopy.address,
// 				gnosisSafeData1
// 			),
// 			"ProxyCreation",
// 			"proxy",
// 			proxyFactory.address,
// 			GnosisSafe,
// 			"create Gnosis Safe 1"
// 		);

// 		gnosisSafe2 = await utils.getParamFromTxEvent(
// 			await proxyFactory.createProxy(
// 				gnosisSafeMasterCopy.address,
// 				gnosisSafeData2
// 			),
// 			"ProxyCreation",
// 			"proxy",
// 			proxyFactory.address,
// 			GnosisSafe,
// 			"create Gnosis Safe 2"
// 		);
// 		console.log("Master Copy address", gnosisSafeMasterCopy.address);
// 		console.log("Safe 1 address", gnosisSafe1.address);
// 		console.log("Safe 2 address", gnosisSafe2.address);

// 		it("safe 1 has an address", async () => {
// 			assert.ok(gnosisSafe1.address);
// 		});
// 		it("safe 2 has an address", async () => {
// 			assert.ok(gnosisSafe2.address);
// 		});

// 		assert.equal(
// 			await gnosisSafe1.name(),
// 			"Token 1",
// 			"name is correctly set for safe 1"
// 		);
// 		assert.equal(
// 			await gnosisSafe1.symbol(),
// 			"TKN1",
// 			"symbol is correctly set for safe 1"
// 		);
// 		assert.equal(
// 			await gnosisSafe2.name(),
// 			"Token 2",
// 			"name is correctly set for safe 2"
// 		);
// 		assert.equal(
// 			await gnosisSafe2.symbol(),
// 			"TKN2",
// 			"symbol is correctly set for safe 2"
// 		);
// 	});
// });

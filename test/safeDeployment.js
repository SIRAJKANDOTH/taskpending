const utils = require("./utils/general");
const CreateAndAddModules = artifacts.require(
	"./libraries/CreateAndAddModules.sol"
);
const ProxyFactory = artifacts.require("./GnosisSafeProxyFactory.sol");
const GnosisSafe = artifacts.require("./GnosisSafe.sol");
const WhitelistModule = artifacts.require("./WhitelistModule.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");

contract("Gnosis Safe", function (accounts) {
	let gnosisSafe1;
	let gnosisSafe2;
	let whitelistModule1;
	let whitelistModule2;
	let lw;
	let gnosisSafeData1, gnosisSafeData2;
	let proxyFactory;
	let gnosisSafeMasterCopy;
	let apContract;

	const CALL = 0;

	beforeEach(async function () {
		// Create lightwallet
		lw = await utils.createLightwallet();

		// Create Master Copies
		proxyFactory = await ProxyFactory.new();
		let createAndAddModules = await CreateAndAddModules.new();
		apContract = await APContract.new();
		let whitelist = await Whitelist.new();

		gnosisSafeMasterCopy = await GnosisSafe.new(apContract.address);
		console.log(
			"master copy controller",
			await gnosisSafeMasterCopy.controller()
		);
		let whitelistModuleMasterCopy = await WhitelistModule.new([]);

		// Create Gnosis Safe and Whitelist Module in one transactions
		let moduleData = await whitelistModuleMasterCopy.contract.methods
			.setup([accounts[3]])
			.encodeABI();

		let proxyFactoryData = await proxyFactory.contract.methods
			.createProxy(whitelistModuleMasterCopy.address, moduleData)
			.encodeABI();

		let modulesCreationData = utils.createAndAddModulesData([proxyFactoryData]);
		let createAndAddModulesData = createAndAddModules.contract.methods
			.createAndAddModules(proxyFactory.address, modulesCreationData)
			.encodeABI();

		await apContract.addAsset("DEX", "DEX Coin", accounts[5], accounts[3]);
		await apContract.addAsset("DAI", "DAI Coin", accounts[5], accounts[4]);

		gnosisSafeData1 = await gnosisSafeMasterCopy.contract.methods
			.setup(
				"Example Safe1",
				"Example Token1",
				"EXM1",
				accounts[2],
				apContract.address,
				[accounts[3], accounts[4]],
				whitelist.address,
				createAndAddModules.address,
				createAndAddModulesData,
				accounts[4]
			)
			.encodeABI();

		gnosisSafeData2 = await gnosisSafeMasterCopy.contract.methods
			.setup(
				"Example Safe2",
				"Example Token2",
				"EXM2",
				accounts[2],
				apContract.address,
				[accounts[3], accounts[4]],
				whitelist.address,
				createAndAddModules.address,
				createAndAddModulesData,
				accounts[4]
			)
			.encodeABI();
	});

	it("should create two safes", async () => {
		gnosisSafe1 = await utils.getParamFromTxEvent(
			await proxyFactory.createProxy(
				gnosisSafeMasterCopy.address,
				gnosisSafeData1
			),
			"ProxyCreation",
			"proxy",
			proxyFactory.address,
			GnosisSafe,
			"create Gnosis Safe 1"
		);

		console.log("name ", await gnosisSafe1.safeName());
		console.log("safe 1 controller ", await gnosisSafe1.controller());

		gnosisSafe2 = await utils.getParamFromTxEvent(
			await proxyFactory.createProxy(
				gnosisSafeMasterCopy.address,
				gnosisSafeData2
			),
			"ProxyCreation",
			"proxy",
			proxyFactory.address,
			GnosisSafe,
			"create Gnosis Safe 2"
		);

		console.log("name2 ", await gnosisSafe2.safeName());
		console.log("safe 2 controller ", await gnosisSafe2.controller());

		it("safe 1 has an address", async () => {
			assert.ok(gnosisSafe1.address);
		});
		it("safe 2 has an address", async () => {
			assert.ok(gnosisSafe2.address);
		});

		let modules1 = await gnosisSafe1.getModules();
		whitelistModule1 = await WhitelistModule.at(modules1[0]);

		let modules2 = await gnosisSafe2.getModules();
		whitelistModule2 = await WhitelistModule.at(modules2[0]);

		assert.equal(await whitelistModule1.manager.call(), gnosisSafe1.address);
		assert.equal(await whitelistModule2.manager.call(), gnosisSafe2.address);

		console.log("token name", await gnosisSafe1.name());
        console.log("token symbol", await gnosisSafe1.symbol());
        

		// it("depositing money to safe", async() => {
		//     gnosisSafe1.deposit()

		// })
	});
});

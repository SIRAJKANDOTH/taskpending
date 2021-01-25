const utils = require("./utils/general");
const GnosisSafe = artifacts.require("./GnosisSafe.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");

contract(" APContract", function (accounts) {
	let newGnosisSafe;
	let newGnosisSafeAddress;
	let gnosisSafeMasterCopy;
	let apContract;
	let whitelist;

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
	});

	it("should add safe to APS", async () => {
		apContract.VaultCreation((err, result) => {
			if (err) console.log("error");
			console.log(result);
			newGnosisSafeAddress = result.args.vaultAddress;
		});

		await apContract.createVault();
		console.log("Address from event", newGnosisSafeAddress);

		assert.ok(newGnosisSafeAddress);

		newGnosisSafe = await GnosisSafe.at(newGnosisSafeAddress);
		await newGnosisSafe.setup(
			// "Example Safe1",
			"Token 1",
			"TKN1",
			// accounts[2],
			apContract.address,
			[accounts[3], accounts[4]],
			[accounts[3], accounts[4]],
			["Group 1", "Group 2"],
			{ from: accounts[0] }
		);

		console.log(
			"Safe in APS",
			await apContract._isVaultPresent(newGnosisSafeAddress)
		);
		assert.equal(
			await apContract.isAssetEnabledInVault(newGnosisSafeAddress, accounts[3]),

			true,
			"The asset is present"
		);
		assert.equal(
			await apContract.isAssetEnabledInVault(
				newGnosisSafeAddress,
				"0x5091af48beb623b3da0a53f726db63e13ff91df9"
			),

			false,
			"The asset is not present"
		);

		assert.equal(
			await newGnosisSafe.name(),
			"Token 1",
			"name is correctly set for safe"
		);
		assert.equal(
			await newGnosisSafe.symbol(),
			"TKN1",
			"symbol is correctly set for safe"
		);

		console.log("vault assets ", await apContract.vaults(newGnosisSafeAddress));
	});
});

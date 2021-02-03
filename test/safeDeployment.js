const utils = require("./utils/general");
const GnosisSafe = artifacts.require("./GnosisSafe.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const ProxyFactory = artifacts.require("./GnosisSafeProxyFactory.sol");
const StrategyMinter = artifacts.require("./strategies/StrategyMinter.sol");
const abi = require("ethereumjs-abi");

contract(" APContract", function (accounts) {
  let newGnosisSafe;
  let newGnosisSafeData;
  let newGnosisSafeAddress;
  let gnosisSafeMasterCopy;
  let apContract;
  let whitelist;
  let proxyFactory;
  let strategyMinter;

  beforeEach(async function () {
    whitelist = await Whitelist.new();
    strategyMinter = await StrategyMinter.new();
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

    await apContract.addProxyFactory(proxyFactory.address);

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

    await apContract.addStrategy("Yearn It All", accounts[5], [accounts[4]]);
    await apContract.addStrategy("Benos Strategy", accounts[6], [accounts[3]]);
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

    // testing strategy minter listner

    console.log("Strateg minter", strategyMinter.address);
    console.log("before minting 11555", await apContract.test());
    // let jsonInterface = {
    //   name: "testCall",
    //   type: "function",
    //   inputs: [
    //     {
    //       type: "string",
    //       name: "newVal",
    //     }
    //   ],
    // };
    // let parameters = ["hello world"];

    // let funcSig = web3.eth.abi.encodeFunctionCall(jsonInterface, parameters);
    // console.log("sign", funcSig);
    await strategyMinter.mintStrategy(
      newGnosisSafe.address,
      "testCall()"
    );
    console.log("after minting 11555", await apContract.test());
     await strategyMinter.mintStrategy(
      newGnosisSafe.address,
      "testWithParameter(string)"
    );
    console.log("after minting 11555 with params", await apContract.test());

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

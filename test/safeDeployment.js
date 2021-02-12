const utils = require("./utils/general");
const GnosisSafe = artifacts.require("./GnosisSafe.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const ProxyFactory = artifacts.require("./GnosisSafeProxyFactory.sol");
const StrategyMinter = artifacts.require("./strategies/StrategyMinter.sol");
const YearnItAll = artifacts.require("./strategies/YearnItAll.sol");
const IERC = artifacts.require("@openzeppelin/contracts/token/ERC20/IERC20.sol");
var abi = require('ethereumjs-abi');

contract(" APContract", function (accounts) {
  let newGnosisSafe;
  let newGnosisSafeData;
  let newGnosisSafeAddress;
  let gnosisSafeMasterCopy;
  let apContract;
  let whitelist;
  let proxyFactory;
  let strategyMinter;
  let yearnItAll;
  let yrt

  beforeEach(async function () {
    yrt = await IERC.at("0x35874F6De93638F53F2C5696c0a22f130486bB7d");
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

    yearnItAll=await YearnItAll.new(apContract.address,["0x72aff7C29C28D659c571b5776c4e4c73eD8355Fb","0xf14f2e832AA11bc4bF8c66A456e2Cb1EaE70BcE9","0xf9a1522387Be6A2f3d442246f5984C508aa98F4e"]
    );

    await apContract.addProxyFactory(proxyFactory.address);
    await apContract.addAsset("YRT", "YRT Coin", accounts[5], "0x35874F6De93638F53F2C5696c0a22f130486bB7d");

    await apContract.addProtocol(
      "crvComp",
      "crvComp Token",
      "0x72aff7C29C28D659c571b5776c4e4c73eD8355Fb"
    );
    await apContract.addProtocol(
      "crvGUSD",
      "crvGUSD Token",
      "0xf14f2e832AA11bc4bF8c66A456e2Cb1EaE70BcE9"
    );
    await apContract.addProtocol(
      "CrvBUSD",
      "CrvBUSD Token",
      "0xf9a1522387Be6A2f3d442246f5984C508aa98F4e"
    );

    await apContract.addStrategy("Yearn It All", yearnItAll.address, ["0x72aff7C29C28D659c571b5776c4e4c73eD8355Fb","0xf14f2e832AA11bc4bF8c66A456e2Cb1EaE70BcE9","0xf9a1522387Be6A2f3d442246f5984C508aa98F4e"]);
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
      ["0x35874F6De93638F53F2C5696c0a22f130486bB7d"],
      ["0x35874F6De93638F53F2C5696c0a22f130486bB7d"],
    );
    await newGnosisSafe.setVaultStrategyAndProtocol(yearnItAll.address,["0x72aff7C29C28D659c571b5776c4e4c73eD8355Fb","0xf14f2e832AA11bc4bF8c66A456e2Cb1EaE70BcE9","0xf9a1522387Be6A2f3d442246f5984C508aa98F4e"],[])
    assert.equal(await newGnosisSafe.vaultName(), "Liva One", "Names match");

    // testing strategy minter listner
    await newGnosisSafe.setVaultActiveStrategy(yearnItAll.address)
    console.log("Safe Name", await newGnosisSafe.vaultName(),yearnItAll.address);
    await newGnosisSafe.setStrategyActiveProtocol('0x72aff7C29C28D659c571b5776c4e4c73eD8355Fb');
    await yrt.approve(newGnosisSafe.address,10);
    // let yrtInitial=await yrt.balanceOf(newGnosisSafe.address);

    // Deposit to safe
    console.log("yrt before deposit",(await yrt.balanceOf(newGnosisSafe.address)).toString())
    await newGnosisSafe.deposit("0x35874F6De93638F53F2C5696c0a22f130486bB7d",10);
    console.log("yrt after deposit",(await yrt.balanceOf(newGnosisSafe.address)).toString())


    // Deposit to Strategy
    console.log("Safe yearn-it-all balance before earning", (await yearnItAll.balanceOf(newGnosisSafe.address)).toString());

    await strategyMinter.mintStrategy(
      newGnosisSafe.address,
      abi.simpleEncode('earn(uint256)',10).toString('hex'),0
    );
    console.log("Safe yearn-it-all balance after earning", (await yearnItAll.balanceOf(newGnosisSafe.address)).toString());







    console.log("Strategy minter", strategyMinter.address);
    console.log("before minting 11555", (await apContract.test()).toString());
    await strategyMinter.mintStrategy(
      newGnosisSafe.address,
      abi.simpleEncode('testCall()').toString('hex'),1
    );
    console.log("after minting 11555", (await apContract.test()).toString());
    console.log("encoded",abi.simpleEncode('testWithParameter(uint256)',155).toString('hex'), "***")
    await strategyMinter.mintStrategy(
      newGnosisSafe.address,
      abi.simpleEncode('testWithParameter(uint256)',255).toString('hex'),1
    );
    console.log("after minting 11555 with params", (await apContract.test()).toString());

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

const utils = require("./utils/general");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const ProxyFactory = artifacts.require("./YieldsterVaultProxyFactory.sol");
const StrategyMinter = artifacts.require("./strategies/StrategyMinter.sol");
const YearnItAll = artifacts.require("./strategies/YearnItAll.sol");
const IERC = artifacts.require("@openzeppelin/contracts/token/ERC20/IERC20.sol");
var abi = require('ethereumjs-abi');

contract(" APContract", function (accounts) {
  let newYieldsterVault;
  let newYieldsterVaultData;
  let newYieldsterVaultAddress;
  let yieldsterVaultMasterCopy;
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
    yieldsterVaultMasterCopy = await utils.deployContract(
      "deploying Yieldster Vault Mastercopy",
      YieldsterVault
    );
    apContract = await APContract.new(
      yieldsterVaultMasterCopy.address,
      whitelist.address
    );

    proxyFactory = await ProxyFactory.new(
      yieldsterVaultMasterCopy.address,
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
      ["0x35874F6De93638F53F2C5696c0a22f130486bB7d"],
      ["0x35874F6De93638F53F2C5696c0a22f130486bB7d"],
    );
    await newYieldsterVault.setVaultStrategyAndProtocol(yearnItAll.address,["0x72aff7C29C28D659c571b5776c4e4c73eD8355Fb","0xf14f2e832AA11bc4bF8c66A456e2Cb1EaE70BcE9","0xf9a1522387Be6A2f3d442246f5984C508aa98F4e"],[])
    assert.equal(await newYieldsterVault.vaultName(), "Liva One", "Names match");

    // testing strategy minter listner
    await newYieldsterVault.setVaultActiveStrategy(yearnItAll.address)
    console.log("Vault Name", await newYieldsterVault.vaultName(),yearnItAll.address);
    await newYieldsterVault.setStrategyActiveProtocol('0x72aff7C29C28D659c571b5776c4e4c73eD8355Fb');
    await yrt.approve(newYieldsterVault.address,10);
    // let yrtInitial=await yrt.balanceOf(newYieldsterVault.address);

    // Deposit to vault
    console.log("yrt before deposit",(await yrt.balanceOf(newYieldsterVault.address)).toString())
    await newYieldsterVault.deposit("0x35874F6De93638F53F2C5696c0a22f130486bB7d",10);
    console.log("yrt after deposit",(await yrt.balanceOf(newYieldsterVault.address)).toString())


    // Deposit to Strategy
    console.log("Vault yearn-it-all balance before earning", (await yearnItAll.balanceOf(newYieldsterVault.address)).toString());

    await strategyMinter.mintStrategy(
      newYieldsterVault.address,
      abi.simpleEncode('earn(uint256)',10).toString('hex'),0
    );
    console.log("Vault yearn-it-all balance after earning", (await yearnItAll.balanceOf(newYieldsterVault.address)).toString());







    console.log("Strategy minter", strategyMinter.address);
    console.log("before minting 11555", (await apContract.test()).toString());
    await strategyMinter.mintStrategy(
      newYieldsterVault.address,
      abi.simpleEncode('testCall()').toString('hex'),1
    );
    console.log("after minting 11555", (await apContract.test()).toString());
    console.log("encoded",abi.simpleEncode('testWithParameter(uint256)',155).toString('hex'), "***")
    await strategyMinter.mintStrategy(
      newYieldsterVault.address,
      abi.simpleEncode('testWithParameter(uint256)',255).toString('hex'),1
    );
    console.log("after minting 11555 with params", (await apContract.test()).toString());

    assert.ok(newYieldsterVault.address);
  

    // apContract.VaultCreation((err, result) => {
    // 	if (err) console.log("error");
    // 	console.log(result);
    // 	newYieldsterVaultAddress = result.args.vaultAddress;
    // });

    // await apContract.createVault();
    // console.log("Address from event", newYieldsterVaultAddress);

    // assert.ok(newYieldsterVaultAddress);

    // newYieldsterVault = await YieldsterVault.at(newYieldsterVaultAddress);
    // await newYieldsterVault.setup(
    // 	// "Example Vault1",
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
    // 	"Vault in APS",
    // 	await apContract._isVaultPresent(newYieldsterVaultAddress)
    // );
    // assert.equal(
    // 	await apContract.isAssetEnabledInVault(newYieldsterVaultAddress, accounts[3]),

    // 	true,
    // 	"The asset is present"
    // );
    // assert.equal(
    // 	await apContract.isAssetEnabledInVault(
    // 		newYieldsterVaultAddress,
    // 		"0x5091af48beb623b3da0a53f726db63e13ff91df9"
    // 	),

    // 	false,
    // 	"The asset is not present"
    // );

    // assert.equal(
    // 	await newYieldsterVault.name(),
    // 	"Token 1",
    // 	"name is correctly set for vault"
    // );
    // assert.equal(
    // 	await newYieldsterVault.symbol(),
    // 	"TKN1",
    // 	"symbol is correctly set for vault"
    // );

    // console.log("vault assets ", await apContract.vaults(newYieldsterVaultAddress));
  });
});

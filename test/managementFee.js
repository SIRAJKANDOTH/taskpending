const utils = require("./utils/general");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const ProxyFactory = artifacts.require("./YieldsterVaultProxyFactory.sol");
const StrategyMinter = artifacts.require("./strategies/StrategyMinter.sol");
const YearnItAll = artifacts.require("./strategies/YearnItAll.sol");
const ManagementFee=artifacts.require("./delegateContracts/ManagementFee.sol");
const YRToken = artifacts.require("./yrToken.sol");
const AishToken = artifacts.require("./aishToken.sol");
const PriceModule = artifacts.require("./price/PriceModule.sol");
const StrategyMinter = artifacts.require("./strategies/StrategyMinter.sol");

function token(n) {
	return web3.utils.toWei(n, "ether");
}

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
  let managementFee;
  let yrtToken;
	let aishToken;
  let priceModule;

  beforeEach(async function () {
  
    whitelist = await Whitelist.new();
    strategyMinter = await StrategyMinter.new();
    
    yieldsterVaultMasterCopy = await utils.deployContract(
      "deploying Yieldster Vault Mastercopy",
      YieldsterVault
    );
	managementFee = await ManagementFee.new();
    apContract = await APContract.new(
      yieldsterVaultMasterCopy.address,
      whitelist.address,
	  managementFee.address
    );
    priceModule = await PriceModule.new(apContract.address);

    proxyFactory = await ProxyFactory.new(
      yieldsterVaultMasterCopy.address,
      apContract.address
    );

    yrtToken = await YRToken.new(token("100000000"));
		aishToken = await AishToken.new(token("100000000"));

    yearnItAll=await YearnItAll.new(apContract.address,["0x72aff7C29C28D659c571b5776c4e4c73eD8355Fb","0xf14f2e832AA11bc4bF8c66A456e2Cb1EaE70BcE9","0xf9a1522387Be6A2f3d442246f5984C508aa98F4e"]
    );
    await apContract.setPriceModule(priceModule.address);
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

  });

  it("should add vault to APS", async () => {
  
   


    assert.equal(await newYieldsterVault.vaultName(), "Liva One", "vault created");



  });

  it("Execute management fee clean Up",async()=>{
    await yrtToken.approve(newYieldsterVault.address, token("100"));
		await newYieldsterVault.deposit(yrtToken.address, token("100"));
    await aishToken.approve(newYieldsterVault.address, token("100"));
		await newYieldsterVault.deposit(aishToken.address, token("100"));

    // Test Management fee
    await newYieldsterVault.managementFeeCleanUp();
    console.log("called")
    console.log("sender balance",(await newYieldsterVault.balanceOf(accounts[0])).toString());
    let result=(await newYieldsterVault.result());
    let currentBlockDifference=await newYieldsterVault.currentBlockDifference();
    let currentNav=await newYieldsterVault.currentNav();
    let calculatedFee=(currentNav*currentBlockDifference*2/100)/2628000;
 
    console.log("result: ",(result).toString());
    console.log("BlockDiffernce: ",(currentBlockDifference).toString());
    console.log("curren Nav: ",(currentNav).toString());
    console.log("calculated Fee ",(calculatedFee).toString());
      assert.equal(parseInt(result),parseInt(calculatedFee),"expected and calculated management Fee matches")

  })
});

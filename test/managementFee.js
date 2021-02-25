const utils = require("./utils/general");
const GnosisSafe = artifacts.require("./GnosisSafe.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const ProxyFactory = artifacts.require("./GnosisSafeProxyFactory.sol");
const StrategyMinter = artifacts.require("./strategies/StrategyMinter.sol");
const YearnItAll = artifacts.require("./strategies/YearnItAll.sol");
const ManagementFee=artifacts.require("./delegateContracts/ManagementFee.sol");

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
  let managementFee;

  beforeEach(async function () {
    managementFee = await ManagementFee.new();
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
   


    assert.equal(await newGnosisSafe.vaultName(), "Liva One", "Safe created");



  });

  it("Execute management fee clean Up",async()=>{
    console.log("test safe: ",(await newGnosisSafe.test()).toString());
    console.log("test management fee :",(await managementFee.test()).toString());
    // Test Management fee
    await newGnosisSafe.managementFeeCleanUp(managementFee.address);
    console.log("called")
    // console.log("sender balance",(await newGnosisSafe.balanceOf(accounts[0])).toString());
 
    console.log("test safe: ",(await newGnosisSafe.test()).toString());
    console.log("test management fee :",(await managementFee.test()).toString());
      assert.equal(1,1,"executed")

  })
});

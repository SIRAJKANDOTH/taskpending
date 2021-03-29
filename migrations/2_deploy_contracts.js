const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const PriceModule = artifacts.require("./price/PriceModule.sol");
const ProxyFactory = artifacts.require(
  "./proxies/YieldsterVaultProxyFactory.sol"
);
const PlatformManagementFee = artifacts.require(
  "./delegateContracts/ManagementFee.sol"
);
const YearnItAll = artifacts.require("./strategies/YearnItAll.sol");
const YearnItAllMinter = artifacts.require("./strategies/YearnItAllMinter.sol");
const HexUtils = artifacts.require("./utils/HexUtils.sol");
const StockDeposit = artifacts.require(
  "./smartStrategies/deposit/StockDeposit.sol"
);
const StockWithdraw = artifacts.require(
  "./smartStrategies/deposit/StockWithdraw.sol"
);
const Exchange = artifacts.require("./exchange/Exchange.sol");

module.exports = async (deployer) => {
  await deployer.deploy(YieldsterVault);
  const yieldsterVaultMasterCopy = await YieldsterVault.deployed();

  await deployer.deploy(PlatformManagementFee);
  const managementFee = await PlatformManagementFee.deployed();

  await deployer.deploy(Whitelist);
  const whitelist = await Whitelist.deployed();

  await deployer.deploy(HexUtils);
  const hexUtils = await HexUtils.deployed();

  await deployer.deploy(
    APContract,
    yieldsterVaultMasterCopy.address,
    whitelist.address,
    managementFee.address,
    hexUtils.address
  );
  const apContract = await APContract.deployed();

  await deployer.deploy(StockDeposit);
  const stockDeposit = await StockDeposit.deployed();

  await deployer.deploy(StockWithdraw);
  const stockWithdraw = await StockWithdraw.deployed();

  await deployer.deploy(Exchange);
  const exchange = await Exchange.deployed();

  await deployer.deploy(PriceModule, apContract.address);
  const priceModule = await PriceModule.deployed();

  await apContract.setPriceModule(priceModule.address);

  await deployer.deploy(
    ProxyFactory,
    yieldsterVaultMasterCopy.address,
    apContract.address
  );
  const proxyFactory = await ProxyFactory.deployed();


  await deployer.deploy(YearnItAll, apContract.address, [
    "0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
    "0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
    "0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
  ]);

  const yearnItAll = await YearnItAll.deployed();

  await deployer.deploy(
    YearnItAllMinter,
    apContract.address,
    yearnItAll.address
  );
  const yearnItAllMinter =await YearnItAllMinter.deployed();
  await apContract.setYieldsterExchange(exchange.address);

  await apContract.setStockDepositWithdraw(
    stockDeposit.address,
    stockWithdraw.address
  );
//   await apContract.setStrategyMinter(yearnItAllMinter.address);

//   await apContract.setStrategyExecutor(
//     "0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0"
//   );

  await apContract.addProxyFactory(proxyFactory.address);

  //adding assets
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

  //adding protocols in the assets for feed address

  await apContract.addAsset(
    "yearn Curve.fi crvCOMP",
    "crvCOMP",
    "0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF",
    "0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8"
  );
  await apContract.addAsset(
    "yearn Curve.fi GUSD/3Crv",
    "crvGUSD",
    "0xd8bD0a1cB028a31AA859A21A3758685a95dE4623",
    "0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e"
  );
  await apContract.addAsset(
    "yearn Curve.fi MUSD/3Crv",
    "crvMUSD",
    "0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB",
    "0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B"
  );

  //adding protocols
  await apContract.addProtocol(
    "yearn Curve.fi crvCOMP",
    "crvCOMP",
    "0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8"
  );
  await apContract.addProtocol(
    "yearn Curve.fi GUSD/3Crv",
    "crvGUSD",
    "0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e"
  );
  await apContract.addProtocol(
    "yearn Curve.fi MUSD/3Crv",
    "crvMUSD",
    "0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B"
  );
//  add accounts
  await apContract.addStrategy("Yearn it All", yearnItAll.address, [
    "0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
    "0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
    "0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
  ],
  yearnItAllMinter.address,
  "0xaC86730Bd6d5d68e004f59C0BC940b92b99D3aEe");
};

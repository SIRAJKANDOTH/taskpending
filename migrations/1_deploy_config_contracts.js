const PlatformManagementFee = artifacts.require("./delegateContracts/ManagementFee.sol");
const ProfitManagementFee = artifacts.require("./delegateContracts/ProfitManagementFee.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const SafeUtils = artifacts.require("./safeUtils/SafeUtils.sol");
const PriceModule = artifacts.require("./price/PriceModule.sol");
const Exchange = artifacts.require("./exchange/Exchange.sol");
const HexUtils = artifacts.require("./utils/HexUtils.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const StockDeposit = artifacts.require("./smartStrategies/deposit/StockDeposit.sol");
const StockWithdraw = artifacts.require("./smartStrategies/deposit/StockWithdraw.sol");
const SafeMinter = artifacts.require("./safeUtils/SafeMinter.sol")
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");

module.exports = async (deployer, network, accounts) => {
    // await deployer.deploy(
    //     PriceModule,
    //     "0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5"
    // );
    // const priceModule = await PriceModule.deployed();
    // await priceModule.addToken("0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9", 1) //DAI
    // await priceModule.addToken("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6", 1) //USDC
    // await priceModule.addToken("0xdac17f958d2ee523a2206206994597c13d831ec7", "0x3E7d1eAB13ad0104d2750B8863b489D65364e32D", 1) //USDT
    // await priceModule.addToken("0x4fabb145d64652a948d72533023f6e7a623c7c53", "0x833D8Eb16D306ed1FbB5D7A2E019e106B960965A", 1) //BUSD
    // await priceModule.addToken("0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490", "0x0000000000000000000000000000000000000000", 2) //3Crv
    // await priceModule.addToken("0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6", "0x0000000000000000000000000000000000000000", 2) //crvUSDP Underlying
    // await priceModule.addToken("0x4f3E8F405CF5aFC05D68142F3783bDfE13811522", "0x0000000000000000000000000000000000000000", 2) //crvUSDN  Underlying
    // await priceModule.addToken("0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c", "0x0000000000000000000000000000000000000000", 2) //crvALUSD Underlying
    // await priceModule.addToken("0xed279fdd11ca84beef15af5d39bb4d4bee23f0ca", "0x0000000000000000000000000000000000000000", 2) //crvLUSD Underlying
    // await priceModule.addToken("0x4807862aa8b2bf68830e4c8dc86d0e9a998e085a", "0x0000000000000000000000000000000000000000", 2) //crvBUSD Underlying
    // await priceModule.addToken("0xC4dAf3b5e2A9e93861c3FBDd25f1e943B8D87417", "0x0000000000000000000000000000000000000000", 3) //crvUSDP
    // await priceModule.addToken("0x3B96d491f067912D18563d56858Ba7d6EC67a6fa", "0x0000000000000000000000000000000000000000", 3) //crvUSDN
    // await priceModule.addToken("0xA74d4B67b3368E83797a35382AFB776bAAE4F5C8", "0x0000000000000000000000000000000000000000", 3) //crvALUSD
    // await priceModule.addToken("0x5fA5B62c8AF877CB37031e0a3B2f34A78e3C56A6", "0x0000000000000000000000000000000000000000", 3) //crvLUSD
    // await priceModule.addToken("0x6Ede7F19df5df6EF23bD5B9CeDb651580Bdf56Ca", "0x0000000000000000000000000000000000000000", 3) //crvBUSD
    // await deployer.deploy(HexUtils);
    await deployer.deploy(PlatformManagementFee);
    await deployer.deploy(ProfitManagementFee);
    await deployer.deploy(SafeUtils);
    await deployer.deploy(Exchange);
    // await deployer.deploy(Whitelist);

    // const hexUtils = await HexUtils.deployed();
    const exchange = await Exchange.deployed();
    const managementFee = await PlatformManagementFee.deployed();
    const profitManagementFee = await ProfitManagementFee.deployed();
    const safeUtils = await SafeUtils.deployed();
    // const whitelist = await Whitelist.deployed();


    await deployer.deploy(
        APContract,
        "0x20996567dBE5c7B1b4c144bac7EE955a17EB23c6",
        managementFee.address,
        profitManagementFee.address,
        "0xAE9a070bed8b80050e3b8A26c169496b55C00D94",
        exchange.address,
        "0x0dAA47FAC1440931A968FA606373Af69EEcd9b83",
        "0xc98435837175795d216547a8edc9e0472604bbda",
        safeUtils.address
    );

    const apContract = await APContract.deployed();

    await deployer.deploy(StockDeposit);
    await deployer.deploy(StockWithdraw);

    const stockDeposit = await StockDeposit.deployed()
    const stockWithdraw = await StockWithdraw.deployed()

    //Adding Assets
    console.log("adding assets")
    await apContract.addAsset("DAI", "DAI Coin", "0x6B175474E89094C44Da98b954EedeAC495271d0F")
    await apContract.addAsset("USDC", "USD Coin", "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
    await apContract.addAsset("USDT", "USDT Coin", "0xdac17f958d2ee523a2206206994597c13d831ec7")
    await apContract.addAsset("BUSD", "BUSD Coin", "0x4fabb145d64652a948d72533023f6e7a623c7c53")


    //adding Protocols
    console.log("adding protocols")
    await apContract.addProtocol(
        "yearn Curve.fi crvUSDP",
        "crvUSDP",
        "0xC4dAf3b5e2A9e93861c3FBDd25f1e943B8D87417"
    );
    await apContract.addProtocol(
        "yearn Curve.fi crvUSDN",
        "crvUSDN",
        "0x3B96d491f067912D18563d56858Ba7d6EC67a6fa"
    );
    await apContract.addProtocol(
        "yearn Curve.fi crvALUSD",
        "crvALUSD",
        "0xA74d4B67b3368E83797a35382AFB776bAAE4F5C8"
    );
    await apContract.addProtocol(
        "yearn Curve.fi crvLUSD",
        "crvLUSD",
        "0x5fA5B62c8AF877CB37031e0a3B2f34A78e3C56A6"
    );
    await apContract.addProtocol(
        "yearn Curve.fi crvBUSD",
        "crvBUSD",
        "0x6Ede7F19df5df6EF23bD5B9CeDb651580Bdf56Ca"
    );

    //Adding Stock withdraw and deposit to APContract
    await apContract.setStockDepositWithdraw(
        stockDeposit.address,
        stockWithdraw.address
    );

    await deployer.deploy(SafeMinter, accounts[0])
    const safeMinter = await SafeMinter.deployed()
    await apContract.setSafeMinter(safeMinter.address);

    await deployer.deploy(YieldsterVault)
    const yieldsterVaultMasterCopy = await YieldsterVault.deployed()

    await deployer.deploy(ProxyFactory, yieldsterVaultMasterCopy.address, apContract.address)
    const proxyFactory = await ProxyFactory.deployed();

    await apContract.addProxyFactory(proxyFactory.address);


};

const APContract = artifacts.require("./aps/APContract.sol");
const StockDeposit = artifacts.require("./smartStrategies/deposit/StockDeposit.sol");
const StockWithdraw = artifacts.require("./smartStrategies/deposit/StockWithdraw.sol");
const SafeMinter = artifacts.require("./safeUtils/SafeMinter.sol")
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const SafeUtils = artifacts.require("./safeUtils/SafeUtils.sol");

module.exports = async (deployer, network, accounts) => {

    await deployer.deploy(SafeUtils);
    let safeUtils = await SafeUtils.deployed()

    await deployer.deploy(
        APContract,
        "0x20996567dBE5c7B1b4c144bac7EE955a17EB23c6",
        "0x477FC30a79881304b07EEc704081e14288bE6670",
        "0xeABbB9D2bace2970361f3e5e15E9f63b14397439",
        "0xAE9a070bed8b80050e3b8A26c169496b55C00D94",
        "0x507F9C130d6405Cd001A9073Adef371dD9fA3F72",
        "0x0dAA47FAC1440931A968FA606373Af69EEcd9b83",
        "0xc98435837175795d216547a8edc9e0472604bbda",
        safeUtils.address //"0x0E6B1f325dD47420823843ff96942a8a627C79A4"
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
    await apContract.addAsset("EURS", "EURS Coin", "0xdB25f211AB05b1c97D595516F45794528a807ad8")
    await apContract.addAsset("sEURS", "sEURS Coin", "0xD71eCFF9342A5Ced620049e616c5035F1dB98620")
    await apContract.addAsset("FRAX", "FRAX Coin", "0x853d955acef822db058eb8505911ed77f175b99e")
    await apContract.addAsset("USDK", "USDK Coin", "0x1c48f86ae57291f7686349f12601910bd8d470bb")
    await apContract.addAsset("USDN", "USDN Coin", "0x674C6Ad92Fd080e4004b2312b45f796a192D27a0")
    await apContract.addAsset("crv3", "crv3 Coin", "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490")
    await apContract.addAsset("uCrvEURS", "uCrvEURS Coin", "0x194eBd173F6cDacE046C53eACcE9B953F28411d1")
    await apContract.addAsset("uCrvUSDK", "uCrvUSDK Coin", "0x97E2768e8E73511cA874545DC5Ff8067eB19B787")
    await apContract.addAsset("uCrvUSDN", "uCrvUSDN Coin", "0x4f3E8F405CF5aFC05D68142F3783bDfE13811522")
    await apContract.addAsset("uCrvBUSD", "uCrvBUSD Coin", "0x4807862aa8b2bf68830e4c8dc86d0e9a998e085a")
    await apContract.addAsset("uCrvFRAX", "uCrvFRAX Coin", "0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B")
    await apContract.addAsset("crvEURS", "crvEURS Coin", "0x25212Df29073FfFA7A67399AcEfC2dd75a831A1A")
    await apContract.addAsset("crvUSDK", "crvUSDK Coin", "0x3D27705c64213A5DcD9D26880c1BcFa72d5b6B0E")
    await apContract.addAsset("crvUSDN", "crvUSDN Coin", "0x3B96d491f067912D18563d56858Ba7d6EC67a6fa")
    await apContract.addAsset("crvBUSD", "crvBUSD Coin", "0x6Ede7F19df5df6EF23bD5B9CeDb651580Bdf56Ca")
    await apContract.addAsset("crvFRAX", "crvFRAX Coin", "0xB4AdA607B9d6b2c9Ee07A275e9616B84AC560139")


    //adding Protocols
    console.log("adding protocols")

    await apContract.addProtocol(
        "convexDeposit contract",
        "CONVEX",
        "0xF403C135812408BFbE8713b5A23a04b3D48AAE31"
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

    console.log(`APS Address :- ${apContract.address}`)
};

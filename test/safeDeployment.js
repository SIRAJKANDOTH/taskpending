const utils = require("./utils/general");
const ERC20 = artifacts.require("IERC20")

const PlatformManagementFee = artifacts.require("./delegateContracts/ManagementFee.sol");
const ProfitManagementFee = artifacts.require("./delegateContracts/ProfitManagementFee.sol");
const Exchange = artifacts.require("./exchange/Exchange.sol");
const SafeUtils = artifacts.require("./safeUtils/SafeUtils.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const PriceModule = artifacts.require("./price/PriceModule.sol");
const HexUtils = artifacts.require("./utils/HexUtils.sol");
const APContract = artifacts.require("./aps/APContract.sol");

const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const StockDeposit = artifacts.require("./smartStrategies/deposit/StockDeposit.sol");
const StockWithdraw = artifacts.require("./smartStrategies/deposit/StockWithdraw.sol");

const LivaOne = artifacts.require("./strategies/LivaOneZapper.sol");
const LivaOneMinter = artifacts.require("./strategies/LivaOneMinter.sol");

const SafeMinter = artifacts.require("./safeUtils/SafeMinter.sol")

var abi = require('ethereumjs-abi');

function to18(n) {
    return web3.utils.toWei(n, "ether");
}
function from18(n) {
    return web3.utils.fromWei(n, "ether");
}
function to6(n) {
    return web3.utils.toWei(n, "Mwei");
}
function from6(n) {
    return web3.utils.fromWei(n, "Mwei");
}
contract("Safe Deployment", function (accounts) {
    let dai, usdc, usdt;
    let uCrvCompToken, uCrvGUSDToken, uCrvBUSDToken;
    let crvComp, crvGUSD, crvBUSD;
    let platformManagemetFee, profitManagementFee, exchange;
    let safeUtils, priceModule, whitelist, hexUtils;
    let proxyFactory, apContract;
    let yieldsterVaultMasterCopy, stockDeposit, stockWithdraw;
    let livaOne, livaOneMinter, safeMinter;

    beforeEach(async function () {
        dai = await ERC20.at("0x6B175474E89094C44Da98b954EedeAC495271d0F")
        usdc = await ERC20.at("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
        usdt = await ERC20.at("0xdac17f958d2ee523a2206206994597c13d831ec7")
        uCrvCompToken = await ERC20.at("0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2")
        uCrvGUSDToken = await ERC20.at("0xD2967f45c4f384DEEa880F807Be904762a3DeA07")
        uCrvBUSDToken = await ERC20.at("0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B")
        crvComp = await ERC20.at("0x629c759D1E83eFbF63d84eb3868B564d9521C129")
        crvGUSD = await ERC20.at("0xcC7E70A958917cCe67B4B87a8C30E6297451aE98")
        crvBUSD = await ERC20.at("0x2994529C0652D127b7842094103715ec5299bBed")

        await dai.transfer(accounts[1], to18("100"))
        await usdc.transfer(accounts[1], to6("100"))
        await usdt.transfer(accounts[1], to6("100"))

        priceModule = await PriceModule.new("0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5");
        await priceModule.addToken("0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9", 1) //DAI
        await priceModule.addToken("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6", 1) //USDC
        await priceModule.addToken("0xdac17f958d2ee523a2206206994597c13d831ec7", "0x3E7d1eAB13ad0104d2750B8863b489D65364e32D", 1) //USDT
        await priceModule.addToken("0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2", "0x0000000000000000000000000000000000000000", 2) //Curve.fi cDAI/cUSDC 
        await priceModule.addToken("0xD2967f45c4f384DEEa880F807Be904762a3DeA07", "0x0000000000000000000000000000000000000000", 2) //Curve.fi GUSD/3Crv
        await priceModule.addToken("0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B", "0x0000000000000000000000000000000000000000", 2) //Curve.fi yDAI/yUSDC/yUSDT/yBUSD
        await priceModule.addToken("0x629c759D1E83eFbF63d84eb3868B564d9521C129", "0x0000000000000000000000000000000000000000", 3) //yearn Curve.fi cDAI/cUSDC
        await priceModule.addToken("0xcC7E70A958917cCe67B4B87a8C30E6297451aE98", "0x0000000000000000000000000000000000000000", 3) //yearn Curve.fi GUSD/3Crv
        await priceModule.addToken("0x2994529C0652D127b7842094103715ec5299bBed", "0x0000000000000000000000000000000000000000", 3) //yearn Curve.fi yDAI/yUSDC/yUSDT/yBUSD


        platformManagemetFee = await PlatformManagementFee.new();
        profitManagementFee = await ProfitManagementFee.new();
        exchange = await Exchange.new();
        safeUtils = await SafeUtils.new();
        hexUtils = await HexUtils.new();
        whitelist = await Whitelist.new();

        apContract = await APContract.new(
            whitelist.address,
            platformManagemetFee.address,
            profitManagementFee.address,
            hexUtils.address,
            exchange.address,
            "0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E",
            priceModule.address,
            safeUtils.address
        );

        yieldsterVaultMasterCopy = await YieldsterVault.new();

        proxyFactory = await ProxyFactory.new(
            yieldsterVaultMasterCopy.address,
            apContract.address
        );

        //Adding proxy factory to the APContract
        await apContract.addProxyFactory(proxyFactory.address);

        stockDeposit = await StockDeposit.new();
        stockWithdraw = await StockWithdraw.new()

        //Adding Stock withdraw and deposit to APContract
        await apContract.setStockDepositWithdraw(
            stockDeposit.address,
            stockWithdraw.address
        );

        //Adding Assets
        console.log("adding assets")
        await apContract.addAsset("DAI", "DAI Coin", "0x6B175474E89094C44Da98b954EedeAC495271d0F")
        await apContract.addAsset("USDC", "USD Coin", "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
        await apContract.addAsset("USDT", "USDT Coin", "0xdac17f958d2ee523a2206206994597c13d831ec7")


        //adding Protocols
        console.log("adding protocols")
        await apContract.addProtocol(
            "yearn Curve.fi crvCOMP",
            "crvCOMP",
            "0x629c759D1E83eFbF63d84eb3868B564d9521C129"
        );
        await apContract.addProtocol(
            "yearn Curve.fi GUSD/3Crv",
            "crvGUSD",
            "0xcC7E70A958917cCe67B4B87a8C30E6297451aE98"
        );
        await apContract.addProtocol(
            "yearn Curve.fi yDAI/yUSDC/yUSDT/yBUSD",
            "crvBUSD",
            "0x2994529C0652D127b7842094103715ec5299bBed"
        );

        livaOne = await LivaOne.new(
            apContract.address,
            [
                "0x629c759D1E83eFbF63d84eb3868B564d9521C129",
                "0xcC7E70A958917cCe67B4B87a8C30E6297451aE98",
                "0x2994529C0652D127b7842094103715ec5299bBed",
            ],
            "0x462991D18666c578F787e9eC0A74Cd18D2971E5F",
            "0xB0880df8420974ef1b040111e5e0e95f05F8fee1"
        );

        livaOneMinter = await LivaOneMinter.new(apContract.address, livaOne.address)

        //adding Liva one to APContract
        console.log('adding strategy')
        await apContract.addStrategy(
            "Liva One",
            livaOne.address,
            [
                "0x629c759D1E83eFbF63d84eb3868B564d9521C129",
                "0xcC7E70A958917cCe67B4B87a8C30E6297451aE98",
                "0x2994529C0652D127b7842094103715ec5299bBed",
            ],
            livaOneMinter.address,
            accounts[0],
            accounts[0],
            "2000000000000000"
        );

        safeMinter = await SafeMinter.new(accounts[0])
        //Adding safe minter to the APContract
        await apContract.setSafeMinter(safeMinter.address);
    });

    it("should create a new vault", async () => {
        testVaultData = await yieldsterVaultMasterCopy.contract.methods
            .setup(
                "Test Vault",
                "Test",
                "T",
                accounts[0],
                apContract.address,
                accounts[0],
                []
            )
            .encodeABI();

        testVault = await utils.getParamFromTxEvent(
            await proxyFactory.createProxy(testVaultData),
            "ProxyCreation",
            "proxy",
            proxyFactory.address,
            YieldsterVault,
            "create Yieldster Vault"
        );

        console.log(
            "vault owner",
            await testVault.owner(),
            "other address",
            accounts[0]
        );

        console.log("Register Vault with APS")
        await testVault.registerVaultWithAPS();

        console.log("Set Vault Assets")
        await testVault.setVaultAssets(
            ["0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", "0xdac17f958d2ee523a2206206994597c13d831ec7"],
            ["0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", "0xdac17f958d2ee523a2206206994597c13d831ec7"],
            [],
            [],
        );

        console.log("set vault strategy and protocol")
        await testVault.setVaultStrategyAndProtocol(
            livaOne.address,
            [
                "0x629c759D1E83eFbF63d84eb3868B564d9521C129",
                "0xcC7E70A958917cCe67B4B87a8C30E6297451aE98",
                "0x2994529C0652D127b7842094103715ec5299bBed"],
            [], []
        )
        assert.equal(await testVault.vaultName(), "Test Vault", "Names match");


        //approve Tokens to vault
        await dai.approve(testVault.address, to18("100"), { from: accounts[1] })
        await usdt.approve(testVault.address, to6("100"), { from: accounts[1] })
        await usdc.approve(testVault.address, to6("100"), { from: accounts[1] })

        console.log("Activating vault strategy ", livaOne.address)
        await testVault.setVaultActiveStrategy(livaOne.address)
        console.log("Vault active strategies", (await testVault.getVaultActiveStrategy()))


        // Deposit to vault
        console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())
        console.log("dai in User before deposit", from18(await dai.balanceOf(accounts[1])).toString())
        console.log("dai in Vault before deposit", from18((await dai.balanceOf(testVault.address)).toString()))
        console.log("usdc in User before deposit", from6((await usdc.balanceOf(accounts[1])).toString()))
        console.log("usdc in Vault before deposit", from6((await usdc.balanceOf(testVault.address)).toString()))
        console.log("usdt in User before deposit", from6((await usdt.balanceOf(accounts[1])).toString()))
        console.log("usdt in Vault before deposit", from6((await usdt.balanceOf(testVault.address)).toString()))
        await testVault.deposit(dai.address, to18("20"), { from: accounts[1] });
        console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())
        console.log("dai in User after deposit", from18(await dai.balanceOf(accounts[1])).toString())
        console.log("dai in Vault after deposit", from18((await dai.balanceOf(testVault.address)).toString()))
        console.log("usdc in User after deposit", from6((await usdc.balanceOf(accounts[1])).toString()))
        console.log("usdc in Vault after deposit", from6((await usdc.balanceOf(testVault.address)).toString()))
        console.log("usdt in User after deposit", from6((await usdt.balanceOf(accounts[1])).toString()))
        console.log("usdt in Vault after deposit", from6((await usdt.balanceOf(testVault.address)).toString()))
        await testVault.deposit(usdc.address, to6("30"), { from: accounts[1] });
        await testVault.deposit(usdt.address, to6("50"), { from: accounts[1] });
        console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())
        console.log("dai in User after deposit", from18(await dai.balanceOf(accounts[1])).toString())
        console.log("dai in Vault after deposit", from18((await dai.balanceOf(testVault.address)).toString()))
        console.log("usdc in User after deposit", from6((await usdc.balanceOf(accounts[1])).toString()))
        console.log("usdc in Vault after deposit", from6((await usdc.balanceOf(testVault.address)).toString()))
        console.log("usdt in User after deposit", from6((await usdt.balanceOf(accounts[1])).toString()))
        console.log("usdt in Vault after deposit", from6((await usdt.balanceOf(testVault.address)).toString()))


        //Withdraw from vault 
        // await testVault.withdraw(usdc.address, 10, { from: accounts[1] });
        // console.log("dai in User after withdraw",from18 (await dai.balanceOf(accounts[1])).toString())
        // console.log("dai in Vault after withdraw", from18((await dai.balanceOf(testVault.address)).toString()))
        // console.log("usdc in User after withdraw", from6((await usdc.balanceOf(accounts[1])).toString()))
        // console.log("usdc in Vault after withdraw", from6((await usdc.balanceOf(testVault.address)).toString()))

        // //Vault protocol
        // console.log("Vault active protocol", (await livaOne.getActiveProtocol(testVault.address)).toString())
        // console.log("activating protocol ", crvComp.address)

        // let setProtocolInstruction = abi.simpleEncode("setActiveProtocol(address)", crvComp.address).toString('hex');
        // console.log("Instruction \n", setProtocolInstruction)
        // await livaOneMinter.mintStrategy(testVault.address, setProtocolInstruction)
        // console.log("Vault active protocol after", (await livaOne.getActiveProtocol(testVault.address)).toString())


        // //Deposit into strategy
        // console.log("livaOne NAV", (await livaOne.getStrategyNAV()).toString())
        // console.log("livaOne token value", web3.utils.fromWei((await livaOne.tokenValueInUSD()).toString(), "ether"))
        // console.log("livaOne token vault balance", (await livaOne.balanceOf(testVault.address)).toString())
        // await livaOneMinter.earn(testVault.address, [dai.address], [50])
        // console.log("livaOne NAV after earn", (await livaOne.getStrategyNAV()).toString())
        // console.log("livaOne token value after earn", web3.utils.fromWei((await livaOne.tokenValueInUSD()).toString(), "ether"))
        // console.log("livaOne token vault balance after earn", (await livaOne.balanceOf(testVault.address)).toString())
        // console.log("livaOne crvComp tokens ", (await crvComp.balanceOf(livaOne.address)).toString())

        // //Change Protocol
        // console.log("Vault active protocol", (await livaOne.getActiveProtocol(testVault.address)).toString())
        // let changeProtocolInstruction = abi.simpleEncode("changeProtocol(address)", crvGUSD.address).toString('hex');
        // console.log("Instruction \n", changeProtocolInstruction)
        // await livaOneMinter.mintStrategy(testVault.address, changeProtocolInstruction)
        // console.log("Vault active protocol after protocol change", (await livaOne.getActiveProtocol(testVault.address)).toString())
        // console.log("livaOne NAV after protocol change", (await livaOne.getStrategyNAV()).toString())
        // console.log("livaOne token value after protocol change", web3.utils.fromWei((await livaOne.tokenValueInUSD()).toString(), "ether"))
        // console.log("livaOne token vault balance after protocol change", (await livaOne.balanceOf(testVault.address)).toString())
        // console.log("livaOne crvComp tokens after protocol change", (await crvComp.balanceOf(livaOne.address)).toString())
        // console.log("livaOne crvGUSD tokens after protocol change", (await crvGUSD.balanceOf(livaOne.address)).toString())

        // //Withdraw from Strategy
        // console.log("usdt in Vault", (await usdt.balanceOf(testVault.address)).toString())
        // let withdrawInstruction = abi.simpleEncode("withdraw(uint256,address)", 50, usdt.address).toString('hex');
        // console.log("Instruction \n", withdrawInstruction)
        // await livaOneMinter.mintStrategy(testVault.address, withdrawInstruction)
        // console.log("livaOne NAV after strategy withdraw", (await livaOne.getStrategyNAV()).toString())
        // console.log("livaOne token value after strategy withdraw", web3.utils.fromWei((await livaOne.tokenValueInUSD()).toString(), "ether"))
        // console.log("livaOne token vault balance after strategy withdraw", (await livaOne.balanceOf(testVault.address)).toString())
        // console.log("livaOne crvComp tokens after strategy withdraw", (await crvComp.balanceOf(livaOne.address)).toString())
        // console.log("livaOne crvGUSD tokens after strategy withdraw", (await crvGUSD.balanceOf(livaOne.address)).toString())
        // console.log("usdt in Vault after strategy withdraw", (await usdt.balanceOf(testVault.address)).toString())
    });
});

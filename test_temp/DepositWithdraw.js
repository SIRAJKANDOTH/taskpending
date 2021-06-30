const utils = require("./utils/general");

const DAI = artifacts.require("DAI")
const USDC = artifacts.require("USDC")
const USDT = artifacts.require("USDT")

const CrvComp = artifacts.require("CrvComp");
const uCrvComp = artifacts.require("uCrvComp")

const CrvGUSD = artifacts.require("CrvGUSD");
const uCrvGUSD = artifacts.require("uCrvGUSD");

const CrvBUSD = artifacts.require("CrvBUSD");
const uCrvBUSD = artifacts.require("uCrvBUSD");

const Zapper = artifacts.require("Zapper")

const PlatformManagementFee = artifacts.require("./delegateContracts/ManagementFee.sol");
const ProfitManagementFee = artifacts.require("./delegateContracts/ProfitManagementFee.sol");
const Exchange = artifacts.require("./exchange/Exchange.sol");
const SafeUtils = artifacts.require("./safeUtils/SafeUtils.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const PriceModule = artifacts.require("./price/PriceModule.sol");
const OneInch = artifacts.require("./oneInchMock/OneInch.sol");
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

contract("Safe Deployment", function (accounts) {
    let dai, usdc, usdt;
    let uCrvCompToken, uCrvGUSDToken, uCrvBUSDToken;
    let crvComp, crvGUSD, crvBUSD;
    let platformManagemetFee, profitManagementFee, exchange;
    let safeUtils, priceModule, whitelist, oneInch, hexUtils;
    let zapper, proxyFactory, apContract;
    let yieldsterVaultMasterCopy, stockDeposit, stockWithdraw;
    let livaOne, livaOneMinter, safeMinter;

    beforeEach(async function () {
        dai = await DAI.new();
        usdc = await USDC.new();
        usdt = await USDT.new();

        uCrvCompToken = await uCrvComp.new();
        uCrvGUSDToken = await uCrvGUSD.new();
        uCrvBUSDToken = await uCrvBUSD.new();


        crvComp = await CrvComp.new(uCrvCompToken.address);
        crvGUSD = await CrvGUSD.new(uCrvGUSDToken.address);
        crvBUSD = await CrvBUSD.new(uCrvBUSDToken.address);

        platformManagemetFee = await PlatformManagementFee.new();
        profitManagementFee = await ProfitManagementFee.new();
        exchange = await Exchange.new();
        safeUtils = await SafeUtils.new();
        hexUtils = await HexUtils.new();
        priceModule = await PriceModule.new();
        whitelist = await Whitelist.new();
        oneInch = await OneInch.new(hexUtils.address, priceModule.address);

        zapper = await Zapper.new(oneInch.address);

        await dai.transfer(accounts[1], "1000000000000000")
        await usdc.transfer(accounts[1], "1000000000000000")
        await usdt.transfer(accounts[1], "1000000000000000")
        await dai.transfer(oneInch.address, "1000000000000000")
        await usdc.transfer(oneInch.address, "1000000000000000")
        await usdt.transfer(oneInch.address, "1000000000000000")
        await uCrvCompToken.transfer(oneInch.address, "1000000000000000")
        await uCrvGUSDToken.transfer(oneInch.address, "1000000000000000")
        await uCrvBUSDToken.transfer(oneInch.address, "1000000000000000")

        apContract = await APContract.new(
            whitelist.address,
            platformManagemetFee.address,
            profitManagementFee.address,
            hexUtils.address,
            exchange.address,
            oneInch.address,
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
        await apContract.addAsset("DAI", "DAI Coin", dai.address)
        await apContract.addAsset("USDC", "USD Coin", usdc.address)
        await apContract.addAsset("USDT", "USDT Coin", usdt.address)

        //adding Protocols
        await apContract.addProtocol(
            "yearn Curve.fi crvCOMP",
            "crvCOMP",
            crvComp.address
        );
        await apContract.addProtocol(
            "yearn Curve.fi GUSD/3Crv",
            "crvGUSD",
            crvGUSD.address
        );
        await apContract.addProtocol(
            "yearn Curve.fi yDAI/yUSDC/yUSDT/yBUSD",
            "crvBUSD",
            crvBUSD.address
        );

        livaOne = await LivaOne.new(
            apContract.address,
            [
                crvComp.address,
                crvGUSD.address,
                crvBUSD.address,
            ],
            zapper.address
        );

        livaOneMinter = await LivaOneMinter.new(apContract.address, livaOne.address)

        //adding Liva one to APContract
        await apContract.addStrategy(
            "Liva One",
            livaOne.address,
            [
                crvComp.address,
                crvGUSD.address,
                crvBUSD.address,
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

        await testVault.registerVaultWithAPS();

        await testVault.setVaultAssets(
            [dai.address, usdc.address, usdt.address],
            [dai.address, usdc.address, usdt.address],
            [],
            [],
        );

        await testVault.setVaultStrategyAndProtocol(
            livaOne.address,
            [
                crvComp.address,
                crvGUSD.address,
                crvBUSD.address,],
            [], []
        )
        assert.equal(await testVault.vaultName(), "Test Vault", "Names match");


        //approve Tokens to vault
        await dai.approve(testVault.address, 10000, { from: accounts[1] })
        await usdt.approve(testVault.address, 10000, { from: accounts[1] })
        await usdc.approve(testVault.address, 10000, { from: accounts[1] })

        console.log("Activating vault strategy ", livaOne.address)
        await testVault.setVaultActiveStrategy(livaOne.address)
        console.log("Vault active strategies", (await testVault.getVaultActiveStrategy()))


        // Deposit to vault
        console.log("dai in User before deposit", (await dai.balanceOf(accounts[1])).toString())
        console.log("dai in Vault before deposit", (await dai.balanceOf(testVault.address)).toString())
        console.log("usdc in User before deposit", (await usdc.balanceOf(accounts[1])).toString())
        console.log("usdc in Vault before deposit", (await usdc.balanceOf(testVault.address)).toString())
        await testVault.deposit(dai.address, 100, { from: accounts[1] });
        console.log("dai in User after deposit", (await dai.balanceOf(accounts[1])).toString())
        console.log("dai in Vault after deposit", (await dai.balanceOf(testVault.address)).toString())
        console.log("usdc in User after deposit", (await usdc.balanceOf(accounts[1])).toString())
        console.log("usdc in Vault after deposit", (await usdc.balanceOf(testVault.address)).toString())


        //Withdraw from vault 
        // await testVault.withdraw(usdc.address, 10, { from: accounts[1] });
        // console.log("dai in User after withdraw", (await dai.balanceOf(accounts[1])).toString())
        // console.log("dai in Vault after withdraw", (await dai.balanceOf(testVault.address)).toString())
        // console.log("usdc in User after withdraw", (await usdc.balanceOf(accounts[1])).toString())
        // console.log("usdc in Vault after withdraw", (await usdc.balanceOf(testVault.address)).toString())

        //Vault protocol
        console.log("Vault active protocol", (await livaOne.getActiveProtocol(testVault.address)).toString())
        console.log("activating protocol ", crvComp.address)

        let setProtocolInstruction = abi.simpleEncode("setActiveProtocol(address)", crvComp.address).toString('hex');
        console.log("Instruction \n", setProtocolInstruction)
        await livaOneMinter.mintStrategy(testVault.address, setProtocolInstruction)
        console.log("Vault active protocol after", (await livaOne.getActiveProtocol(testVault.address)).toString())


        //Deposit into strategy
        console.log("livaOne NAV", (await livaOne.getStrategyNAV()).toString())
        console.log("livaOne token value", web3.utils.fromWei((await livaOne.tokenValueInUSD()).toString(), "ether"))
        console.log("livaOne token vault balance", (await livaOne.balanceOf(testVault.address)).toString())
        await livaOneMinter.earn(testVault.address, [dai.address], [50])
        console.log("livaOne NAV after earn", (await livaOne.getStrategyNAV()).toString())
        console.log("livaOne token value after earn", web3.utils.fromWei((await livaOne.tokenValueInUSD()).toString(), "ether"))
        console.log("livaOne token vault balance after earn", (await livaOne.balanceOf(testVault.address)).toString())
        console.log("livaOne crvComp tokens ", (await crvComp.balanceOf(livaOne.address)).toString())

        //Change Protocol
        console.log("Vault active protocol", (await livaOne.getActiveProtocol(testVault.address)).toString())
        let changeProtocolInstruction = abi.simpleEncode("changeProtocol(address)", crvGUSD.address).toString('hex');
        console.log("Instruction \n", changeProtocolInstruction)
        await livaOneMinter.mintStrategy(testVault.address, changeProtocolInstruction)
        console.log("Vault active protocol after protocol change", (await livaOne.getActiveProtocol(testVault.address)).toString())
        console.log("livaOne NAV after protocol change", (await livaOne.getStrategyNAV()).toString())
        console.log("livaOne token value after protocol change", web3.utils.fromWei((await livaOne.tokenValueInUSD()).toString(), "ether"))
        console.log("livaOne token vault balance after protocol change", (await livaOne.balanceOf(testVault.address)).toString())
        console.log("livaOne crvComp tokens after protocol change", (await crvComp.balanceOf(livaOne.address)).toString())
        console.log("livaOne crvGUSD tokens after protocol change", (await crvGUSD.balanceOf(livaOne.address)).toString())

        //Withdraw from Strategy
        console.log("usdt in Vault", (await usdt.balanceOf(testVault.address)).toString())
        let withdrawInstruction = abi.simpleEncode("withdraw(uint256,address)", 50, usdt.address).toString('hex');
        console.log("Instruction \n", withdrawInstruction)
        await livaOneMinter.mintStrategy(testVault.address, withdrawInstruction)
        console.log("livaOne NAV after strategy withdraw", (await livaOne.getStrategyNAV()).toString())
        console.log("livaOne token value after strategy withdraw", web3.utils.fromWei((await livaOne.tokenValueInUSD()).toString(), "ether"))
        console.log("livaOne token vault balance after strategy withdraw", (await livaOne.balanceOf(testVault.address)).toString())
        console.log("livaOne crvComp tokens after strategy withdraw", (await crvComp.balanceOf(livaOne.address)).toString())
        console.log("livaOne crvGUSD tokens after strategy withdraw", (await crvGUSD.balanceOf(livaOne.address)).toString())
        console.log("usdt in Vault after strategy withdraw", (await usdt.balanceOf(testVault.address)).toString())
    });
});

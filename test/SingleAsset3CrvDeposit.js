const utils = require("./utils/general");
const ERC20 = artifacts.require("IERC20")
const APContract = artifacts.require("./aps/APContract.sol");
const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const SingleAsset3Crv = artifacts.require("./strategies/SingleAsset3Crv/SingleAsset3Crv.sol");
const SingleAsset3CrvMinter = artifacts.require("./strategies/SingleAsset3Crv/SingleAsset3CrvMinter.sol");

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
contract("Strategy Deposit", function (accounts) {
    let dai, usdc, usdt, busd;
    let uCrvUSDPToken, uCrvUSDNToken, uCrvBUSDToken, uCrvALUSDToken, uCrvLUSDToken;
    let crvUSDP, crvUSDN, crvALUSD, crvLUSD, crvBUSD, crv3;
    let proxyFactory, apContract;
    let yieldsterVaultMasterCopy;
    let singleAsset3Crv, singleAsset3CrvMinter;
    let apContractAddress = "0xC162aC1be63b8cC7755E645e590AedC7680D497b";
    let yieldsterVaultMasterCopyAddress = "0x481898B0b758964A75009073afD9121562300086";
    let proxyFactoryAddress = "0x9fE33228cd2858251a6BBfc3AFc866504bE1Ae91";
    let singleAsset3CrvAddress = "0x8fae3FA452Df8e716950E03Db382107dB6341E92";
    let singleAsset3CrvMinterAddress = "0xB1AF79B2b9eD07d85752c5a82Be860D25E813910";

    beforeEach(async function () {

        dai = await ERC20.at("0x6B175474E89094C44Da98b954EedeAC495271d0F")
        usdc = await ERC20.at("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
        usdt = await ERC20.at("0xdac17f958d2ee523a2206206994597c13d831ec7")
        busd = await ERC20.at("0x4fabb145d64652a948d72533023f6e7a623c7c53")
        uCrvUSDPToken = await ERC20.at("0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6")
        uCrvUSDNToken = await ERC20.at("0x4f3E8F405CF5aFC05D68142F3783bDfE13811522")
        uCrvALUSDToken = await ERC20.at("0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c")
        uCrvLUSDToken = await ERC20.at("0xed279fdd11ca84beef15af5d39bb4d4bee23f0ca")
        uCrvBUSDToken = await ERC20.at("0x4807862aa8b2bf68830e4c8dc86d0e9a998e085a")
        crvUSDP = await ERC20.at("0xC4dAf3b5e2A9e93861c3FBDd25f1e943B8D87417")
        crvUSDN = await ERC20.at("0x3B96d491f067912D18563d56858Ba7d6EC67a6fa")
        crvALUSD = await ERC20.at("0xA74d4B67b3368E83797a35382AFB776bAAE4F5C8")
        crvLUSD = await ERC20.at("0x5fA5B62c8AF877CB37031e0a3B2f34A78e3C56A6")
        crvBUSD = await ERC20.at("0x6Ede7F19df5df6EF23bD5B9CeDb651580Bdf56Ca")
        crv3 = await ERC20.at("0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490")

        await dai.transfer(accounts[1], to18("100"))
        await busd.transfer(accounts[1], to18("100"))
        await usdc.transfer(accounts[1], to6("100"))
        await usdt.transfer(accounts[1], to6("100"))

        apContract = await APContract.at(apContractAddress);
        singleAsset3Crv = await SingleAsset3Crv.at(singleAsset3CrvAddress)
        yieldsterVaultMasterCopy = await YieldsterVault.at(yieldsterVaultMasterCopyAddress)
        proxyFactory = await ProxyFactory.at(proxyFactoryAddress)
        singleAsset3CrvMinter = await SingleAsset3CrvMinter.at(singleAsset3CrvMinterAddress)

    });

    it("should create a new vault", async () => {
        testVaultData = await yieldsterVaultMasterCopy.contract.methods
            .setup(
                "Test",
                "T",
                accounts[0],
                apContractAddress,
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
            [dai.address, usdc.address, usdt.address, busd.address, crv3.address],
            [dai.address, usdc.address, usdt.address, busd.address, crv3.address],
            [],
            [],
        );

        console.log("set vault strategy and protocol")
        await testVault.setVaultStrategyAndProtocol(
            singleAsset3CrvAddress,
            [
                crvBUSD.address,
            ],
            [], []
        )


        //approve Tokens to vault
        await busd.approve(testVault.address, to18("100"), { from: accounts[1] })
        await dai.approve(testVault.address, to18("100"), { from: accounts[1] })
        await usdt.approve(testVault.address, to6("100"), { from: accounts[1] })
        await usdc.approve(testVault.address, to6("100"), { from: accounts[1] })

        console.log("Activating vault strategy ", singleAsset3CrvAddress)
        await testVault.setVaultActiveStrategy(singleAsset3CrvAddress)
        console.log("Vault active strategies", (await testVault.getVaultActiveStrategy()))


        // Deposit to vault
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        console.log("dai in User =", from18(await dai.balanceOf(accounts[1])).toString())
        console.log("dai in Vault =", from18((await dai.balanceOf(testVault.address)).toString()))
        console.log("usdc in User =", from6((await usdc.balanceOf(accounts[1])).toString()))
        console.log("usdc in Vault =", from6((await usdc.balanceOf(testVault.address)).toString()))
        console.log("usdt in User =", from6((await usdt.balanceOf(accounts[1])).toString()))
        console.log("usdt in Vault =", from6((await usdt.balanceOf(testVault.address)).toString()))
        console.log("busd in User =", from18((await busd.balanceOf(accounts[1])).toString()))
        console.log("busd in Vault =", from18((await busd.balanceOf(testVault.address)).toString()))
        console.log("===========================DEPOSIT=============================")
        await testVault.deposit(dai.address, to18("100"), { from: accounts[1] });
        await testVault.deposit(usdt.address, to6("100"), { from: accounts[1] });
        await testVault.deposit(busd.address, to18("100"), { from: accounts[1] });
        await testVault.deposit(usdc.address, to6("100"), { from: accounts[1] });
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        console.log("dai in User =", from18(await dai.balanceOf(accounts[1])).toString())
        console.log("dai in Vault =", from18((await dai.balanceOf(testVault.address)).toString()))
        console.log("usdc in User =", from6((await usdc.balanceOf(accounts[1])).toString()))
        console.log("usdc in Vault =", from6((await usdc.balanceOf(testVault.address)).toString()))
        console.log("usdt in User =", from6((await usdt.balanceOf(accounts[1])).toString()))
        console.log("usdt in Vault =", from6((await usdt.balanceOf(testVault.address)).toString()))
        console.log("busd in User =", from18((await busd.balanceOf(accounts[1])).toString()))
        console.log("busd in Vault =", from18((await busd.balanceOf(testVault.address)).toString()))
        //Withdraw from vault 
        // console.log("===========================WITHDRAW=============================")
        // let estimatedReturns = await curve3Pool.calc_token_amount([daiInVault, 0, 0], true);
        // console.log("Estimated returns=>>>>>>", estimatedReturns)
        // await testVault.withdraw(usdc.address, to18("250"), { from: accounts[1] });
        // await testVault.withdraw(usdt.address, to18("250"), { from: accounts[1] });
        // console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        // console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        // console.log("dai in User =", from18(await dai.balanceOf(accounts[1])).toString())
        // console.log("dai in Vault =", from18((await dai.balanceOf(testVault.address)).toString()))
        // console.log("usdc in User =", from6((await usdc.balanceOf(accounts[1])).toString()))
        // console.log("usdc in Vault =", from6((await usdc.balanceOf(testVault.address)).toString()))
        // console.log("usdt in User =", from6((await usdt.balanceOf(accounts[1])).toString()))
        // console.log("usdt in Vault =", from6((await usdt.balanceOf(testVault.address)).toString()))
        // console.log("busd in User =", from18((await busd.balanceOf(accounts[1])).toString()))
        // console.log("busd in Vault =", from18((await busd.balanceOf(testVault.address)).toString()))

        //Deposit into strategy
        console.log("singleAsset3Crv NAV =", from18((await singleAsset3Crv.getStrategyNAV()).toString()))
        console.log("singleAsset3Crv token value =", from18((await singleAsset3Crv.tokenValueInUSD()).toString()))
        console.log("singleAsset3Crv token vault balance =", from18((await singleAsset3Crv.balanceOf(testVault.address)).toString()))
        console.log("singleAsset3Crv crvBUSD tokens  =", from18((await crvBUSD.balanceOf(singleAsset3CrvAddress)).toString()))
        console.log("===================STRATEGY DEPOSIT=====================")
        let earnInstruction =
            web3.eth.abi.encodeParameters(['address[3]', 'uint256[3]', 'uint256', 'address[]', 'uint256[]'], [["0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", "0xdac17f958d2ee523a2206206994597c13d831ec7"], [`${to18("100")}`, `${to6("100")}`, `${to6("100")}`], "0", ["0x4fabb145d64652a948d72533023f6e7a623c7c53"], [`${to18("100")}`]]);

        await singleAsset3CrvMinter.earn(testVault.address, [dai.address, usdc.address, usdt.address, busd.address], [to18("100"), to6("100"), to6("100"), to18("100")], earnInstruction)
        console.log("singleAsset3Crv NAV =", from18((await singleAsset3Crv.getStrategyNAV()).toString()))
        console.log("singleAsset3Crv token value =", from18((await singleAsset3Crv.tokenValueInUSD()).toString()))
        console.log("singleAsset3Crv token vault balance =", from18((await singleAsset3Crv.balanceOf(testVault.address)).toString()))
        console.log("singleAsset3Crv crvBUSD tokens  =", from18((await crvBUSD.balanceOf(singleAsset3CrvAddress)).toString()))
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())

        //Withdraw from Strategy
        console.log("====================STRATEGY WITHDRAW===================================")
        console.log("usdc in Vault", from6((await usdc.balanceOf(testVault.address)).toString()))
        console.log("busd in Vault", from18((await busd.balanceOf(testVault.address)).toString()))
        console.log("crv3 in Vault", from18((await crv3.balanceOf(testVault.address)).toString()))
        console.log("uCrvBUSDToken in Vault", from18((await uCrvBUSDToken.balanceOf(testVault.address)).toString()))
        let withdrawInstruction = abi.simpleEncode("withdraw(uint256,address)", to18("100"), uCrvBUSDToken.address).toString('hex');
        console.log("Instruction \n", withdrawInstruction)
        await singleAsset3CrvMinter.mintStrategy(testVault.address, withdrawInstruction)
        console.log("singleAsset3Crv NAV after strategy withdraw", from18((await singleAsset3Crv.getStrategyNAV()).toString()))
        console.log("singleAsset3Crv token value after strategy withdraw", from18((await singleAsset3Crv.tokenValueInUSD()).toString()))
        console.log("singleAsset3Crv token vault balance after strategy withdraw", from18((await singleAsset3Crv.balanceOf(testVault.address)).toString()))
        console.log("singleAsset3Crv crvBUSD tokens after strategy withdraw", from18((await crvBUSD.balanceOf(singleAsset3CrvAddress)).toString()))
        console.log("usdc in Vault after strategy withdraw", from6((await usdc.balanceOf(testVault.address)).toString()))
        console.log("busd in Vault after strategy withdraw", from18((await busd.balanceOf(testVault.address)).toString()))
        console.log("crv3 in Vault after strategy withdraw", from18((await crv3.balanceOf(testVault.address)).toString()))
        console.log("uCrvBUSDToken in Vault after strategy withdraw", from18((await uCrvBUSDToken.balanceOf(testVault.address)).toString()))


        // //Withdraw from vault 
        // console.log("===========================WITHDRAW=============================")
        // await testVault.withdraw(dai.address, to18("100"), { from: accounts[1] });
        // console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        // console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())
        // console.log("dai in User ", from18(await dai.balanceOf(accounts[1])).toString())
        // console.log("dai in Vault ", from18((await dai.balanceOf(testVault.address)).toString()))
        // console.log("usdc in User ", from6((await usdc.balanceOf(accounts[1])).toString()))
        // console.log("usdc in Vault ", from6((await usdc.balanceOf(testVault.address)).toString()))
        // console.log("usdt in User", from6((await usdt.balanceOf(accounts[1])).toString()))
        // console.log("usdt in Vault", from6((await usdt.balanceOf(testVault.address)).toString()))
        // console.log("busd in User ", from18((await busd.balanceOf(accounts[1])).toString()))
        // console.log("busd in Vault ", from18((await busd.balanceOf(testVault.address)).toString()))

    });
});

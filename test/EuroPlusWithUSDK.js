const utils = require("./utils/general");
const ERC20 = artifacts.require("IERC20")
const APContract = artifacts.require("./aps/APContract.sol");
const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const EuroPlus = artifacts.require("./strategies/EuroPlus/EuroPlus.sol");
const EuroPlusMinter = artifacts.require("./strategies/EuroPlus/EuroPlusMinter.sol");

function to18(n) {
    return web3.utils.toWei(n, "ether");
}
function from18(n) {
    return web3.utils.fromWei(n, "ether");
}

contract("Strategy Deposit", function (accounts) {
    let usdk, crv3;
    let uCrvUSDKToken;
    let crvUSDK;
    let proxyFactory, apContract;
    let yieldsterVaultMasterCopy;
    let euroPlus, euroPlusMinter;

    beforeEach(async function () {

        usdk = await ERC20.at("0x1c48f86ae57291f7686349f12601910bd8d470bb")
        crv3 = await ERC20.at("0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490")
        uCrvUSDKToken = await ERC20.at("0x97E2768e8E73511cA874545DC5Ff8067eB19B787")
        crvUSDK = await ERC20.at("0x3D27705c64213A5DcD9D26880c1BcFa72d5b6B0E")

        await usdk.transfer(accounts[1], to18("8549"))
        // await crv3.transfer(accounts[1], to18("100"))

        apContract = await APContract.deployed();
        euroPlus = await EuroPlus.deployed()
        yieldsterVaultMasterCopy = await YieldsterVault.deployed()
        proxyFactory = await ProxyFactory.deployed()
        euroPlusMinter = await EuroPlusMinter.deployed()

    });

    it("should create a new vault", async () => {
        testVaultData = await yieldsterVaultMasterCopy.contract.methods
            .setup(
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
            [usdk.address, crv3.address, crvUSDK.address, uCrvUSDKToken.address],
            [usdk.address, crv3.address, crvUSDK.address, uCrvUSDKToken.address],
            [],
            [],
        );

        console.log("set vault strategy and protocol")
        await testVault.setVaultStrategyAndProtocol(
            euroPlus.address,
            [
                crvUSDK.address,
            ],
            [], []
        )


        //approve Tokens to vault
        await usdk.approve(testVault.address, to18("8549"), { from: accounts[1] })
        // await crv3.approve(testVault.address, to18("100"), { from: accounts[1] })

        console.log("Activating vault strategy ", euroPlus.address)
        await testVault.setVaultActiveStrategy(euroPlus.address)
        console.log("Vault active strategies", (await testVault.getVaultActiveStrategy()))


        // Deposit to vault
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        console.log("usdk in User =", from18(await usdk.balanceOf(accounts[1])).toString())
        console.log("usdk in Vault =", from18((await usdk.balanceOf(testVault.address)).toString()))
        console.log("crv3 in User =", from18((await crv3.balanceOf(accounts[1])).toString()))
        console.log("crv3 in Vault =", from18((await crv3.balanceOf(testVault.address)).toString()))
        console.log("===========================DEPOSIT=============================")
        await testVault.deposit(usdk.address, to18("8549"), { from: accounts[1] });
        // await testVault.deposit(crv3.address, to18("100"), { from: accounts[1] });
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        console.log("usdk in User =", from18(await usdk.balanceOf(accounts[1])).toString())
        console.log("usdk in Vault =", from18((await usdk.balanceOf(testVault.address)).toString()))
        console.log("crv3 in User =", from18((await crv3.balanceOf(accounts[1])).toString()))
        console.log("crv3 in Vault =", from18((await crv3.balanceOf(testVault.address)).toString()))

        //Withdraw from vault 
        // console.log("===========================WITHDRAW=============================")
        // console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        // console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        // console.log("usdk in User =", from18(await usdk.balanceOf(accounts[1])).toString())
        // console.log("usdk in Vault =", from18((await usdk.balanceOf(testVault.address)).toString()))
        // console.log("crv3 in User =", from18((await crv3.balanceOf(accounts[1])).toString()))
        // console.log("crv3 in Vault =", from18((await crv3.balanceOf(testVault.address)).toString()))
        // crvUSDK

        //Deposit into strategy
        console.log("euroPlus NAV =", from18((await euroPlus.getStrategyNAV()).toString()))
        console.log("euroPlus token value =", from18((await euroPlus.tokenValueInUSD()).toString()))
        console.log("euroPlus token vault balance =", from18((await euroPlus.balanceOf(testVault.address)).toString()))
        console.log("===================STRATEGY DEPOSIT=====================")
        let earnInstruction =
            web3.eth.abi.encodeParameters(['address[2]', 'uint256[2]', 'uint256', 'address[]', 'address[]'], [["0x1c48f86ae57291f7686349f12601910bd8d470bb", "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490"], [`${to18("7495")}`, `${to18("0")}`], "0", [], []]);

        await euroPlusMinter.earn(testVault.address, [usdk.address], [to18("7495")], earnInstruction)
        console.log("euroPlus NAV =", from18((await euroPlus.getStrategyNAV()).toString()))
        console.log("euroPlus token value =", from18((await euroPlus.tokenValueInUSD()).toString()))
        console.log("euroPlus token vault balance =", from18((await euroPlus.balanceOf(testVault.address)).toString()))
        console.log("euroPlus crvUSDK tokens  =", from18((await crvUSDK.balanceOf(euroPlus.address)).toString()))
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())

        // //Withdraw from Strategy
        // console.log("====================STRATEGY WITHDRAW===================================")
        // console.log("usdk in Vault", from18((await usdk.balanceOf(testVault.address)).toString()))
        // console.log("crv3 in Vault", from18((await crv3.balanceOf(testVault.address)).toString()))
        // console.log("crvUSDK in Vault", from18((await crvUSDK.balanceOf(testVault.address)).toString()))
        // console.log("uCrvUSDKToken in Vault", from18((await uCrvUSDKToken.balanceOf(testVault.address)).toString()))
        // let withdrawInstruction = abi.simpleEncode("withdraw(uint256,address)", to18("50"), uCrvUSDKToken.address).toString('hex');
        // console.log("Instruction \n", withdrawInstruction)
        // await euroPlusMinter.mintStrategy(testVault.address, withdrawInstruction)
        // console.log("euroPlus NAV after strategy withdraw", from18((await euroPlus.getStrategyNAV()).toString()))
        // console.log("euroPlus token value after strategy withdraw", from18((await euroPlus.tokenValueInUSD()).toString()))
        // console.log("euroPlus token vault balance after strategy withdraw", from18((await euroPlus.balanceOf(testVault.address)).toString()))
        // console.log("euroPlus crvUSDK tokens after strategy withdraw", from18((await crvUSDK.balanceOf(euroPlus.address)).toString()))
        // console.log("usdk in Vault", from18((await usdk.balanceOf(testVault.address)).toString()))
        // console.log("crv3 in Vault", from18((await crv3.balanceOf(testVault.address)).toString()))
        // console.log("crvUSDK in Vault", from18((await crvUSDK.balanceOf(testVault.address)).toString()))
        // console.log("uCrvUSDKToken in Vault", from18((await uCrvUSDKToken.balanceOf(testVault.address)).toString()))
        // //Withdraw from vault 
        // console.log("===========================WITHDRAW=============================")
        // await testVault.withdraw(usdk.address, to18("100"), { from: accounts[1] });
        // console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        // console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())
        // console.log("usdk in User ", from18(await usdk.balanceOf(accounts[1])).toString())
        // console.log("usdk in Vault ", from18((await usdk.balanceOf(testVault.address)).toString()))
        // console.log("crv3 in User ", from18((await crv3.balanceOf(accounts[1])).toString()))
        // console.log("crv3 in Vault ", from18((await crv3.balanceOf(testVault.address)).toString()))

    });
});

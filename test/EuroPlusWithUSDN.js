const utils = require("./utils/general");
const ERC20 = artifacts.require("IERC20")
const APContract = artifacts.require("./aps/APContract.sol");
const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const EuroPlus = artifacts.require("./strategies/EuroPlus/EuroPlus.sol");
const EuroPlusMinter = artifacts.require("./strategies/EuroPlus/EuroPlusMinter.sol");

var abi = require('ethereumjs-abi');

function to18(n) {
    return web3.utils.toWei(n, "ether");
}
function from18(n) {
    return web3.utils.fromWei(n, "ether");
}

contract("Strategy Deposit", function (accounts) {
    let usdn, crv3;
    let uCrvUSDNToken;
    let crvUSDN;
    let proxyFactory, apContract;
    let yieldsterVaultMasterCopy;
    let euroPlus, euroPlusMinter;

    beforeEach(async function () {

        usdn = await ERC20.at("0x674C6Ad92Fd080e4004b2312b45f796a192D27a0")
        crv3 = await ERC20.at("0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490")
        uCrvUSDNToken = await ERC20.at("0x4f3E8F405CF5aFC05D68142F3783bDfE13811522")
        crvUSDN = await ERC20.at("0x3B96d491f067912D18563d56858Ba7d6EC67a6fa")

        await usdn.transfer(accounts[1], to18("8549"))
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
            [usdn.address, crv3.address, crvUSDN.address, uCrvUSDNToken.address],
            [usdn.address, crv3.address, crvUSDN.address, uCrvUSDNToken.address],
            [],
            [],
        );

        console.log("set vault strategy and protocol")
        await testVault.setVaultStrategyAndProtocol(
            euroPlus.address,
            [
                crvUSDN.address,
            ],
            [], []
        )


        //approve Tokens to vault
        await usdn.approve(testVault.address, to18("8549"), { from: accounts[1] })
        // await crv3.approve(testVault.address, to18("100"), { from: accounts[1] })

        console.log("Activating vault strategy ", euroPlus.address)
        await testVault.setVaultActiveStrategy(euroPlus.address)
        console.log("Vault active strategies", (await testVault.getVaultActiveStrategy()))


        // Deposit to vault
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        console.log("usdn in User =", from18(await usdn.balanceOf(accounts[1])).toString())
        console.log("usdn in Vault =", from18((await usdn.balanceOf(testVault.address)).toString()))
        console.log("crv3 in User =", from18((await crv3.balanceOf(accounts[1])).toString()))
        console.log("crv3 in Vault =", from18((await crv3.balanceOf(testVault.address)).toString()))
        console.log("===========================DEPOSIT=============================")
        await testVault.deposit(usdn.address, to18("8549"), { from: accounts[1] });
        // await testVault.deposit(crv3.address, to18("100"), { from: accounts[1] });
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        console.log("usdn in User =", from18(await usdn.balanceOf(accounts[1])).toString())
        console.log("usdn in Vault =", from18((await usdn.balanceOf(testVault.address)).toString()))
        console.log("crv3 in User =", from18((await crv3.balanceOf(accounts[1])).toString()))
        console.log("crv3 in Vault =", from18((await crv3.balanceOf(testVault.address)).toString()))

        //Withdraw from vault 
        // console.log("===========================WITHDRAW=============================")
        // console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        // console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        // console.log("usdn in User =", from18(await usdn.balanceOf(accounts[1])).toString())
        // console.log("usdn in Vault =", from18((await usdn.balanceOf(testVault.address)).toString()))
        // console.log("crv3 in User =", from18((await crv3.balanceOf(accounts[1])).toString()))
        // console.log("crv3 in Vault =", from18((await crv3.balanceOf(testVault.address)).toString()))
        // crvUSDN

        //Deposit into strategy
        console.log("euroPlus NAV =", from18((await euroPlus.getStrategyNAV()).toString()))
        console.log("euroPlus token value =", from18((await euroPlus.tokenValueInUSD()).toString()))
        console.log("euroPlus token vault balance =", from18((await euroPlus.balanceOf(testVault.address)).toString()))
        console.log("===================STRATEGY DEPOSIT=====================")
        let earnInstruction =
            web3.eth.abi.encodeParameters(['address[2]', 'uint256[2]', 'uint256', 'address[]', 'address[]'], [["0x674C6Ad92Fd080e4004b2312b45f796a192D27a0", "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490"], [`${to18("7495")}`, `${to18("0")}`], "0", [], []]);

        await euroPlusMinter.earn(testVault.address, [usdn.address], [to18("7495")], earnInstruction)
        console.log("euroPlus NAV =", from18((await euroPlus.getStrategyNAV()).toString()))
        console.log("euroPlus token value =", from18((await euroPlus.tokenValueInUSD()).toString()))
        console.log("euroPlus token vault balance =", from18((await euroPlus.balanceOf(testVault.address)).toString()))
        console.log("euroPlus crvUSDN tokens  =", from18((await crvUSDN.balanceOf(euroPlus.address)).toString()))
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())

        // //Withdraw from Strategy
        // console.log("====================STRATEGY WITHDRAW===================================")
        // console.log("usdn in Vault", from18((await usdn.balanceOf(testVault.address)).toString()))
        // console.log("crv3 in Vault", from18((await crv3.balanceOf(testVault.address)).toString()))
        // console.log("crvUSDN in Vault", from18((await crvUSDN.balanceOf(testVault.address)).toString()))
        // console.log("uCrvUSDNToken in Vault", from18((await uCrvUSDNToken.balanceOf(testVault.address)).toString()))
        // let withdrawInstruction = abi.simpleEncode("withdraw(uint256,address)", to18("50"), uCrvUSDNToken.address).toString('hex');
        // console.log("Instruction \n", withdrawInstruction)
        // await euroPlusMinter.mintStrategy(testVault.address, withdrawInstruction)
        // console.log("euroPlus NAV after strategy withdraw", from18((await euroPlus.getStrategyNAV()).toString()))
        // console.log("euroPlus token value after strategy withdraw", from18((await euroPlus.tokenValueInUSD()).toString()))
        // console.log("euroPlus token vault balance after strategy withdraw", from18((await euroPlus.balanceOf(testVault.address)).toString()))
        // console.log("euroPlus crvUSDN tokens after strategy withdraw", from18((await crvUSDN.balanceOf(euroPlus.address)).toString()))
        // console.log("usdn in Vault", from18((await usdn.balanceOf(testVault.address)).toString()))
        // console.log("crv3 in Vault", from18((await crv3.balanceOf(testVault.address)).toString()))
        // console.log("crvUSDN in Vault", from18((await crvUSDN.balanceOf(testVault.address)).toString()))
        // console.log("uCrvUSDNToken in Vault", from18((await uCrvUSDNToken.balanceOf(testVault.address)).toString()))
        // //Withdraw from vault 
        // console.log("===========================WITHDRAW=============================")
        // await testVault.withdraw(usdn.address, to18("100"), { from: accounts[1] });
        // console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        // console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())
        // console.log("usdn in User ", from18(await usdn.balanceOf(accounts[1])).toString())
        // console.log("usdn in Vault ", from18((await usdn.balanceOf(testVault.address)).toString()))
        // console.log("crv3 in User ", from18((await crv3.balanceOf(accounts[1])).toString()))
        // console.log("crv3 in Vault ", from18((await crv3.balanceOf(testVault.address)).toString()))

    });
});

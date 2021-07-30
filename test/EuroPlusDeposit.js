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
function to2(n) {
    return (n * 100).toString();
}
function from2(n) {
    return (n / 100).toString();
}

contract("Strategy Deposit", function (accounts) {
    let eurs, sEurs;
    let uCrvEursToken;
    let crvEURS;
    let proxyFactory, apContract;
    let yieldsterVaultMasterCopy;
    let euroPlus, euroPlusMinter;
    let apContractAddress = "0x79787838b2Df609adf7B614e90dD8A9B207Eae65";
    let yieldsterVaultMasterCopyAddress = "0x1F8e8bB98Cc88D473499a251C97d7Aa18f885cDC";
    let proxyFactoryAddress = "0xf2832923BD433968B10b9c018433957b791bD37e";
    let euroPlusAddress = "0x9015E3AAA74CF482A7F66b75Fc036d3a2247Bb9F";
    let euroPlusMinterAddress = "0x141603f83C4f63FE5Aa1341B256868F9F562f145";

    beforeEach(async function () {

        eurs = await ERC20.at("0xdB25f211AB05b1c97D595516F45794528a807ad8")
        sEurs = await ERC20.at("0xD71eCFF9342A5Ced620049e616c5035F1dB98620")
        uCrvEursToken = await ERC20.at("0x194eBd173F6cDacE046C53eACcE9B953F28411d1")
        crvEURS = await ERC20.at("0x25212Df29073FfFA7A67399AcEfC2dd75a831A1A")

        await eurs.transfer(accounts[1], to2("100"))
        // await sEurs.transfer(accounts[1], to18("100"))

        apContract = await APContract.at(apContractAddress);
        euroPlus = await EuroPlus.at(euroPlusAddress)
        yieldsterVaultMasterCopy = await YieldsterVault.at(yieldsterVaultMasterCopyAddress)
        proxyFactory = await ProxyFactory.at(proxyFactoryAddress)
        euroPlusMinter = await EuroPlusMinter.at(euroPlusMinterAddress)

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
            [eurs.address, sEurs.address],
            [eurs.address, sEurs.address],
            [],
            [],
        );

        console.log("set vault strategy and protocol")
        await testVault.setVaultStrategyAndProtocol(
            euroPlusAddress,
            [
                crvEURS.address,
            ],
            [], []
        )


        //approve Tokens to vault
        await eurs.approve(testVault.address, to2("100"), { from: accounts[1] })
        // await sEurs.approve(testVault.address, to18("100"), { from: accounts[1] })

        console.log("Activating vault strategy ", euroPlusAddress)
        await testVault.setVaultActiveStrategy(euroPlusAddress)
        console.log("Vault active strategies", (await testVault.getVaultActiveStrategy()))


        // Deposit to vault
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        console.log("eurs in User =", from2(await eurs.balanceOf(accounts[1])).toString())
        console.log("eurs in Vault =", from2((await eurs.balanceOf(testVault.address)).toString()))
        console.log("sEurs in User =", from18((await sEurs.balanceOf(accounts[1])).toString()))
        console.log("sEurs in Vault =", from18((await sEurs.balanceOf(testVault.address)).toString()))
        console.log("===========================DEPOSIT=============================")
        await testVault.deposit(eurs.address, to2("100"), { from: accounts[1] });
        // await testVault.deposit(sEurs.address, to18("100"), { from: accounts[1] });
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        console.log("eurs in User =", from2(await eurs.balanceOf(accounts[1])).toString())
        console.log("eurs in Vault =", from2((await eurs.balanceOf(testVault.address)).toString()))
        console.log("sEurs in User =", from18((await sEurs.balanceOf(accounts[1])).toString()))
        console.log("sEurs in Vault =", from18((await sEurs.balanceOf(testVault.address)).toString()))

        //Withdraw from vault 
        // console.log("===========================WITHDRAW=============================")
        // console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        // console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        // console.log("eurs in User =", from2(await eurs.balanceOf(accounts[1])).toString())
        // console.log("eurs in Vault =", from2((await eurs.balanceOf(testVault.address)).toString()))
        // console.log("sEurs in User =", from18((await sEurs.balanceOf(accounts[1])).toString()))
        // console.log("sEurs in Vault =", from18((await sEurs.balanceOf(testVault.address)).toString()))
        // crvEURS

        //Deposit into strategy
        console.log("euroPlus NAV =", from18((await euroPlus.getStrategyNAV()).toString()))
        console.log("euroPlus token value =", from18((await euroPlus.tokenValueInUSD()).toString()))
        console.log("euroPlus token vault balance =", from18((await euroPlus.balanceOf(testVault.address)).toString()))
        console.log("===================STRATEGY DEPOSIT=====================")
        let earnInstruction =
            web3.eth.abi.encodeParameters(['address[2]', 'uint256[2]', 'uint256', 'address[]', 'address[]'], [["0xdB25f211AB05b1c97D595516F45794528a807ad8", "0xD71eCFF9342A5Ced620049e616c5035F1dB98620"], [`${to2("100")}`, `${to18("0")}`], "0", [], []]);

        await euroPlusMinter.earn(testVault.address, [eurs.address], [to2("100")], earnInstruction)
        console.log("euroPlus NAV =", from18((await euroPlus.getStrategyNAV()).toString()))
        console.log("euroPlus token value =", from18((await euroPlus.tokenValueInUSD()).toString()))
        console.log("euroPlus token vault balance =", from18((await euroPlus.balanceOf(testVault.address)).toString()))
        console.log("euroPlus crvEURS tokens  =", from18((await crvEURS.balanceOf(euroPlusAddress)).toString()))
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())

        //Withdraw from Strategy
        console.log("====================STRATEGY WITHDRAW===================================")
        console.log("eurs in Vault", from2((await eurs.balanceOf(testVault.address)).toString()))
        let withdrawInstruction = abi.simpleEncode("withdraw(uint256,address)", to18("50"), eurs.address).toString('hex');
        console.log("Instruction \n", withdrawInstruction)
        await euroPlusMinter.mintStrategy(testVault.address, withdrawInstruction)
        console.log("euroPlus NAV after strategy withdraw", from18((await euroPlus.getStrategyNAV()).toString()))
        console.log("euroPlus token value after strategy withdraw", from18((await euroPlus.tokenValueInUSD()).toString()))
        console.log("euroPlus token vault balance after strategy withdraw", from18((await euroPlus.balanceOf(testVault.address)).toString()))
        console.log("euroPlus crvEURS tokens after strategy withdraw", from18((await crvEURS.balanceOf(euroPlusAddress)).toString()))
        console.log("eurs in Vault", from2((await eurs.balanceOf(testVault.address)).toString()))

        // //Withdraw from vault 
        // console.log("===========================WITHDRAW=============================")
        // await testVault.withdraw(eurs.address, to18("100"), { from: accounts[1] });
        // console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        // console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())
        // console.log("eurs in User ", from2(await eurs.balanceOf(accounts[1])).toString())
        // console.log("eurs in Vault ", from2((await eurs.balanceOf(testVault.address)).toString()))
        // console.log("sEurs in User ", from18((await sEurs.balanceOf(accounts[1])).toString()))
        // console.log("sEurs in Vault ", from18((await sEurs.balanceOf(testVault.address)).toString()))

    });
});

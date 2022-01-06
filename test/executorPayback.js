const utils = require("./utils/general");
const ERC20 = artifacts.require("IERC20")
const APContract = artifacts.require("./aps/APContract.sol");
const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
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
contract("executor Payback", function (accounts) {
    let usdc, usdt;
    let crvUSDN;
    let proxyFactory, apContract;
    let yieldsterVaultMasterCopy;
    let safeMinter;

    beforeEach(async function () {

        usdc = await ERC20.at("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
        usdt = await ERC20.at("0xdac17f958d2ee523a2206206994597c13d831ec7")
        crvUSDN = await ERC20.at("0x3B96d491f067912D18563d56858Ba7d6EC67a6fa")


        apContract = await APContract.deployed();
        yieldsterVaultMasterCopy = await YieldsterVault.deployed()
        proxyFactory = await ProxyFactory.deployed()
        safeMinter = await SafeMinter.deployed()

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
            accounts[0],
            "deployed vault",
            testVault.address,
            "aps",
            apContract.address
        );

        console.log("Register Vault with APS")
        await testVault.registerVaultWithAPS();

        console.log("Set Vault Assets")
        await testVault.setVaultAssets(
            [usdc.address, usdt.address],
            [usdc.address, usdt.address],
            [],
            [],
        );


        //approve Tokens to vault
        await usdt.approve(testVault.address, to6("10000"), { from: accounts[0] })
        await usdc.approve(testVault.address, to6("10000"), { from: accounts[0] })



        // Deposit to vault
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        console.log("usdc in User =", from6((await usdc.balanceOf(accounts[0])).toString()))
        console.log("usdc in Vault =", from6((await usdc.balanceOf(testVault.address)).toString()))
        console.log("usdt in User =", from6((await usdt.balanceOf(accounts[0])).toString()))
        console.log("usdt in Vault =", from6((await usdt.balanceOf(testVault.address)).toString()))

        console.log("===========================DEPOSIT=============================")
        await testVault.deposit(usdt.address, to6("10000"), { from: accounts[0] });
        await testVault.deposit(usdc.address, to6("10000"), { from: accounts[0] });
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        console.log("usdc in User =", from6((await usdc.balanceOf(accounts[0])).toString()))
        console.log("usdc in Vault =", from6((await usdc.balanceOf(testVault.address)).toString()))
        console.log("usdt in User =", from6((await usdt.balanceOf(accounts[0])).toString()))
        console.log("usdt in Vault =", from6((await usdt.balanceOf(testVault.address)).toString()))

        console.log("===========================EXECUTOR PAYBACK=============================")
        console.log("usdt in beneficiary =", from6((await usdt.balanceOf(accounts[1])).toString()))
        console.log("usdc in beneficiary =", from6((await usdc.balanceOf(accounts[1])).toString()))

        let executorPaybackInstruction = abi.simpleEncode("paybackExecutor(uint256[],address[],address[])", ["1000000000", "1000000000"], [accounts[1], accounts[1]], [usdt.address, usdc.address]);
        
        console.log(executorPaybackInstruction)
        await safeMinter.mintStrategy(testVault.address, executorPaybackInstruction)
        console.log("usdt in beneficiary =", from6((await usdt.balanceOf(accounts[1])).toString()))
        console.log("usdc in beneficiary =", from6((await usdc.balanceOf(accounts[1])).toString()))


        // console.log("===============================TEST=======================================")

        // let safeMinterInstruction = abi.simpleEncode('test()').toString('hex');
        // console.log("Instruction \n", safeMinterInstruction)
        // await safeMinter.mintStrategy(testVault.address, '0xf8a8fd6d')
    });
});

// let executorPaybackInstruction = abi.simpleEncode("paybackExecutor(uint256[],address[],address[])", ["848000000", "684000000"], ["0xb2AA4a5DF3641D42e72D7F07a40292794dfD07a0","0xb2AA4a5DF3641D42e72D7F07a40292794dfD07a0"], ["0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48","0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"]).toString('hex');



//  805367 before

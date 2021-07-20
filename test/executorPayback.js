const utils = require("./utils/general");
const ERC20 = artifacts.require("IERC20")
const APContract = artifacts.require("./aps/APContract.sol");
const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const LivaOne = artifacts.require("./strategies/LivaOne/LivaOneCrv.sol");
const LivaOneMinter = artifacts.require("./strategies/LivaOne/LivaOneMinter.sol");
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
    let dai, usdc, usdt, busd;
    let uCrvUSDPToken, uCrvUSDNToken, uCrvBUSDToken, uCrvALUSDToken, uCrvLUSDToken;
    let crvUSDP, crvUSDN, crvALUSD, crvLUSD, crvBUSD, crv3;
    let proxyFactory, apContract;
    let yieldsterVaultMasterCopy;
    let livaOne, livaOneMinter, safeMinter;
    let apContractAddress = "0x23d6A8272A912A85919447d9793e39Fa1b442D15";
    let safeMinterAddress = "0x9D1f2777fCa43743cB6c1b9E6fa68e6ecaADD94d"
    let yieldsterVaultMasterCopyAddress = "0x0dA2F4e0863A187AF8b27f97Efa377Eaa4a88396";
    let proxyFactoryAddress = "0x4169136d1C858d2AD071727C3A44baEb43d4Ccd2";
    let livaOneAddress = "0x4e742FfcC314586Dda357CE94A4BE08b77B273A3";
    let livaOneMinterAddress = "0xAb7c7a46663400ef0225a8a42DF2eE6194E7e47e";


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

        // await dai.transfer(accounts[1], to18("5000"))
        // await busd.transfer(accounts[1], to18("100"))
        await usdc.transfer(accounts[1], to6("1000"))
        await usdt.transfer(accounts[1], to6("1000"))

        apContract = await APContract.at(apContractAddress);
        livaOne = await LivaOne.at(livaOneAddress)
        yieldsterVaultMasterCopy = await YieldsterVault.at(yieldsterVaultMasterCopyAddress)
        proxyFactory = await ProxyFactory.at(proxyFactoryAddress)
        livaOneMinter = await LivaOneMinter.at(livaOneMinterAddress)
        safeMinter = await SafeMinter.at(safeMinterAddress)

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
            [dai.address, usdc.address, usdt.address, busd.address],
            [dai.address, usdc.address, usdt.address, busd.address],
            [],
            [],
        );

        console.log("set vault strategy and protocol")
        await testVault.setVaultStrategyAndProtocol(
            livaOneAddress,
            [
                crvUSDP.address,
                crvUSDN.address,
                crvALUSD.address,
                crvLUSD.address,
                crvBUSD.address,
            ],
            [], []
        )


        //approve Tokens to vault
        // await busd.approve(testVault.address, to18("100"), { from: accounts[1] })
        // await dai.approve(testVault.address, to18("5000"), { from: accounts[1] })
        await usdt.approve(testVault.address, to6("1000"), { from: accounts[1] })
        await usdc.approve(testVault.address, to6("1000"), { from: accounts[1] })

        console.log("Activating vault strategy ", livaOneAddress)
        await testVault.setVaultActiveStrategy(livaOneAddress)
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
        await testVault.deposit(usdt.address, to6("1000"), { from: accounts[1] });
        // await testVault.deposit(dai.address, to18("5000"), { from: accounts[1] });
        // await testVault.deposit(busd.address, to18("100"), { from: accounts[1] });
        await testVault.deposit(usdc.address, to6("1000"), { from: accounts[1] });
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

        console.log("===========================EXECUTOR PAYBACK=============================")
        console.log("usdt in beneficiary =", from6((await usdt.balanceOf(accounts[3])).toString()))
        console.log("usdc in beneficiary =", from6((await usdc.balanceOf(accounts[3])).toString()))

        let executorPaybackInstruction = abi.simpleEncode("paybackExecutor(uint256[],address[],address[])", ["260000000000000000", "260000000000000000"], [accounts[3], accounts[3]], [usdt.address, usdc.address]).toString('hex');
        console.log("Instruction \n", executorPaybackInstruction)
        await safeMinter.mintStrategy(testVault.address, executorPaybackInstruction)
        console.log("Vault active protocol after", (await livaOne.getActiveProtocol(testVault.address)).toString())
        console.log("usdt in beneficiary =", from6((await usdt.balanceOf(accounts[3])).toString()))
        console.log("usdc in beneficiary =", from6((await usdc.balanceOf(accounts[3])).toString()))

    });
});

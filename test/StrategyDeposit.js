const utils = require("./utils/general");
const ERC20 = artifacts.require("IERC20")
const APContract = artifacts.require("./aps/APContract.sol");
const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const LivaOne = artifacts.require("./interfaces/IStrategy.sol");
const LivaOneMinter = artifacts.require("./strategies/LivaOneMinter.sol");

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
    let dai, usdc, usdt;
    let uCrvUSDPToken, uCrvUSDNToken, uCrvBUSDToken, uCrvALUSDToken, uCrvLUSDToken;
    let crvUSDP, crvUSDN, crvALUSD, crvLUSD, crvBUSD;
    let proxyFactory, apContract;
    let yieldsterVaultMasterCopy;
    let livaOne, livaOneMinter;
    let apContractAddress = "0xA8A48Ec23D0B64d3F756183dA214185B5703963A";
    let livaOneAddress = "0x651aF6473dE9Bf97e4f489c3351956283A92d94b";
    let yieldsterVaultMasterCopyAddress = "0xFd6e114e08ebaB8c84CC3DBa3c59Cac673c179aB";
    let proxyFactoryAddress = "0x92a3e2b080305B2d90814652867B5F8dC4aE27b9";
    let livaOneMinterAddress = "0x7D3f57A5eC702a13029c3BD2a77b742EE8492444"
    beforeEach(async function () {
        dai = await ERC20.at("0x6B175474E89094C44Da98b954EedeAC495271d0F")
        usdc = await ERC20.at("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
        usdt = await ERC20.at("0xdac17f958d2ee523a2206206994597c13d831ec7")
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

        await dai.transfer(accounts[1], to18("100"))
        await usdc.transfer(accounts[1], to6("100"))
        await usdt.transfer(accounts[1], to6("100"))

        apContract = await APContract.at(apContractAddress);
        livaOne = await LivaOne.at(livaOneAddress)
        yieldsterVaultMasterCopy = await YieldsterVault.at(yieldsterVaultMasterCopyAddress)
        proxyFactory = await ProxyFactory.at(proxyFactoryAddress)
        livaOneMinter = await LivaOneMinter.at(livaOneMinterAddress)

    });

    it("should create a new vault", async () => {
        testVaultData = await yieldsterVaultMasterCopy.contract.methods
            .setup(
                "Test Vault",
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
            [dai.address, usdc.address, usdt.address],
            [dai.address, usdc.address, usdt.address],
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
        assert.equal(await testVault.vaultName(), "Test Vault", "Names match");


        //approve Tokens to vault
        await dai.approve(testVault.address, to18("100"), { from: accounts[1] })
        await usdt.approve(testVault.address, to6("100"), { from: accounts[1] })
        await usdc.approve(testVault.address, to6("100"), { from: accounts[1] })

        console.log("Activating vault strategy ", livaOneAddress)
        await testVault.setVaultActiveStrategy(livaOneAddress)
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
        console.log("===========================DEPOSIT=============================")
        await testVault.deposit(dai.address, to18("100"), { from: accounts[1] });
        await testVault.deposit(usdc.address, to6("100"), { from: accounts[1] });
        await testVault.deposit(usdt.address, to6("100"), { from: accounts[1] });
        console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())
        console.log("dai in User after deposit", from18(await dai.balanceOf(accounts[1])).toString())
        console.log("dai in Vault after deposit", from18((await dai.balanceOf(testVault.address)).toString()))
        console.log("usdc in User after deposit", from6((await usdc.balanceOf(accounts[1])).toString()))
        console.log("usdc in Vault after deposit", from6((await usdc.balanceOf(testVault.address)).toString()))
        console.log("usdt in User after deposit", from6((await usdt.balanceOf(accounts[1])).toString()))
        console.log("usdt in Vault after deposit", from6((await usdt.balanceOf(testVault.address)).toString()))

        // //Withdraw from vault 
        // console.log("===========================WITHDRAW=============================")
        // await testVault.withdraw(dai.address, to18("100"), { from: accounts[1] });
        // console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        // console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())
        // console.log("dai in User after withdraw", from18(await dai.balanceOf(accounts[1])).toString())
        // console.log("dai in Vault after withdraw", from18((await dai.balanceOf(testVault.address)).toString()))
        // console.log("usdc in User after withdraw", from6((await usdc.balanceOf(accounts[1])).toString()))
        // console.log("usdc in Vault after withdraw", from6((await usdc.balanceOf(testVault.address)).toString()))
        // console.log("usdt in User after deposit", from6((await usdt.balanceOf(accounts[1])).toString()))
        // console.log("usdt in Vault after deposit", from6((await usdt.balanceOf(testVault.address)).toString()))
        // crvUSDP,crvUSDN,crvALUSD,crvLUSD,crvBUSD,
        //Vault protocol
        console.log("Vault active protocol", (await livaOne.getActiveProtocol(testVault.address)).toString())
        console.log("activating protocol ", crvALUSD.address)

        let setProtocolInstruction = abi.simpleEncode("setActiveProtocol(address)", crvALUSD.address).toString('hex');
        console.log("Instruction \n", setProtocolInstruction)
        await livaOneMinter.mintStrategy(testVault.address, setProtocolInstruction)
        console.log("Vault active protocol after", (await livaOne.getActiveProtocol(testVault.address)).toString())


        //Deposit into strategy
        console.log("livaOne NAV", from18((await livaOne.getStrategyNAV({ from: testVault.address })).toString()))
        console.log("livaOne token value", from18((await livaOne.tokenValueInUSD({ from: testVault.address })).toString()))
        console.log("livaOne token vault balance", from18((await livaOne.balanceOf(testVault.address)).toString()))
        console.log("===================STRATEGY DEPOSIT=====================")
        let earnInstruction =
            web3.eth.abi.encodeParameters(['address[3]', 'uint256[3]', 'uint256', 'address[]', 'address[]'], [["0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", "0xdac17f958d2ee523a2206206994597c13d831ec7"], [`${to18("100")}`, `${to6("100")}`, `${to6("100")}`], "0", [], []]);

        await livaOneMinter.earn(testVault.address, [dai.address, usdc.address, usdt.address], [to18("100"), to6("100"), to6("100")], earnInstruction)
        console.log("livaOne NAV", from18((await livaOne.getStrategyNAV({ from: testVault.address })).toString()))
        console.log("livaOne token value", from18((await livaOne.tokenValueInUSD({ from: testVault.address })).toString()))
        console.log("livaOne token vault balance", from18((await livaOne.balanceOf(testVault.address)).toString()))
        console.log("livaOne crvALUSD tokens ", from18((await crvALUSD.balanceOf(livaOneAddress)).toString()))
        console.log("livaOne crvBUSD tokens ", from18((await crvBUSD.balanceOf(livaOneAddress)).toString()))
        console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())

        //Change Protocol
        console.log("==================CHANGE PROTOCOL====================")
        console.log("Vault active protocol", (await livaOne.getActiveProtocol(testVault.address)).toString())
        let changeProtocolInstruction = abi.simpleEncode("changeProtocol(address)", crvBUSD.address).toString('hex');
        await livaOneMinter.mintStrategy(testVault.address, changeProtocolInstruction)
        console.log("Vault active protocol after protocol change", (await livaOne.getActiveProtocol(testVault.address)).toString())
        console.log("livaOne NAV after protocol change", from18((await livaOne.getStrategyNAV({ from: testVault.address })).toString()))
        console.log("livaOne token value after protocol change", from18((await livaOne.tokenValueInUSD({ from: testVault.address })).toString()))
        console.log("livaOne token vault balance after protocol change", from18((await livaOne.balanceOf(testVault.address)).toString()))
        console.log("livaOne crvALUSD tokens after protocol change", from18((await crvALUSD.balanceOf(livaOneAddress)).toString()))
        console.log("livaOne crvBUSD tokens after protocol change", from18((await crvBUSD.balanceOf(livaOneAddress)).toString()))
        console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())
        // //Withdraw from Strategy
        // console.log("usdt in Vault", (await usdt.balanceOf(testVault.address)).toString())
        // let withdrawInstruction = abi.simpleEncode("withdraw(uint256,address)", 50, usdt.address).toString('hex');
        // console.log("Instruction \n", withdrawInstruction)
        // await livaOneMinter.mintStrategy(testVault.address, withdrawInstruction)
        // console.log("livaOne NAV after strategy withdraw", from18((await livaOne.getStrategyNAV()).toString()))
        // console.log("livaOne token value after strategy withdraw", from18((await livaOne.tokenValueInUSD()).toString()))
        // console.log("livaOne token vault balance after strategy withdraw", from18((await livaOne.balanceOf(testVault.address)).toString()))
        // console.log("livaOne crvALUSD tokens after strategy withdraw", from18((await crvALUSD.balanceOf(livaOneAddress)).toString()))
        // console.log("livaOne crvBUSD tokens after strategy withdraw", from18((await crvBUSD.balanceOf(livaOneAddress)).toString()))
        // console.log("usdt in Vault after strategy withdraw", (await usdt.balanceOf(testVault.address)).toString())
    });
});

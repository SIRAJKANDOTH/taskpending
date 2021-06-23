const utils = require("./utils/general");
const ERC20 = artifacts.require("IERC20")
const APContract = artifacts.require("./aps/APContract.sol");
const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const LivaOne = artifacts.require("./strategies/LivaOneZapper.sol");
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
    let apContractAddress = "0xD13004479D203F59feC05b2E32C0053A2bD536CE";
    let livaOneAddress = "0x721A84CC7E298283AD17bc977eD9e9b20a661F98";
    let livaOneMinterAddress = "0x30a3E50dF4992A9ed9D60F89a461fb3819A3d97F";
    let yieldsterVaultMasterCopyAddress = "0x2232a52993CBa25B0919FBB14dC485694a523CC1";
    let proxyFactoryAddress = "0xBA64eD2bcf7E8B053155A967FB270d3BdC2E6326";

    beforeEach(async function () {
        dai = await ERC20.at("0x6B175474E89094C44Da98b954EedeAC495271d0F")
        usdc = await ERC20.at("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
        usdt = await ERC20.at("0xdac17f958d2ee523a2206206994597c13d831ec7")
        uCrvUSDPToken = await ERC20.at("0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6")
        uCrvUSDNToken = await ERC20.at("0x4f3E8F405CF5aFC05D68142F3783bDfE13811522")
        uCrvALUSDToken = await ERC20.at("0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c")
        uCrvLUSDToken = await ERC20.at("0xed279fdd11ca84beef15af5d39bb4d4bee23f0ca")
        uCrvBUSDToken = await ERC20.at("0x4807862aa8b2bf68830e4c8dc86d0e9a998e085a")
        crvUSDP = await ERC20.at("0x3B96d491f067912D18563d56858Ba7d6EC67a6fa")
        crvUSDN = await ERC20.at("0x3B96d491f067912D18563d56858Ba7d6EC67a6fa")
        crvALUSD = await ERC20.at("0xA74d4B67b3368E83797a35382AFB776bAAE4F5C8")
        crvLUSD = await ERC20.at("0x5fA5B62c8AF877CB37031e0a3B2f34A78e3C56A6")
        crvBUSD = await ERC20.at("0x6Ede7F19df5df6EF23bD5B9CeDb651580Bdf56Ca")

        await dai.transfer(accounts[1], to18("100"))
        await usdc.transfer(accounts[1], to6("100"))
        await usdt.transfer(accounts[1], to6("100"))


        apContract = await APContract.at(apContractAddress);
        livaOne = await LivaOne.at(livaOneAddress)
        livaOneMinter = await LivaOneMinter.at(livaOneMinterAddress)
        yieldsterVaultMasterCopy = await YieldsterVault.at(yieldsterVaultMasterCopyAddress)
        proxyFactory = await ProxyFactory.at(proxyFactoryAddress)
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
        await testVault.withdraw(usdc.address, to6("10"), { from: accounts[1] });
        console.log("dai in User after withdraw", from18(await dai.balanceOf(accounts[1])).toString())
        console.log("dai in Vault after withdraw", from18((await dai.balanceOf(testVault.address)).toString()))
        console.log("usdc in User after withdraw", from6((await usdc.balanceOf(accounts[1])).toString()))
        console.log("usdc in Vault after withdraw", from6((await usdc.balanceOf(testVault.address)).toString()))

        //Vault protocol
        console.log("Vault active protocol", (await livaOne.getActiveProtocol(testVault.address)).toString())
        console.log("activating protocol ", crvUSDP.address)

        let setProtocolInstruction = abi.simpleEncode("setActiveProtocol(address)", crvUSDP.address).toString('hex');
        console.log("Instruction \n", setProtocolInstruction)
        await livaOneMinter.mintStrategy(testVault.address, setProtocolInstruction)
        console.log("Vault active protocol after", (await livaOne.getActiveProtocol(testVault.address)).toString())


        // //Deposit into strategy
        // console.log("livaOne NAV", (await livaOne.getStrategyNAV()).toString())
        // console.log("livaOne token value", web3.utils.fromWei((await livaOne.tokenValueInUSD()).toString(), "ether"))
        // console.log("livaOne token vault balance", (await livaOne.balanceOf(testVault.address)).toString())
        // await livaOneMinter.earn(testVault.address, [dai.address], [50])
        // console.log("livaOne NAV after earn", (await livaOne.getStrategyNAV()).toString())
        // console.log("livaOne token value after earn", web3.utils.fromWei((await livaOne.tokenValueInUSD()).toString(), "ether"))
        // console.log("livaOne token vault balance after earn", (await livaOne.balanceOf(testVault.address)).toString())
        // console.log("livaOne crvUSDP tokens ", (await crvUSDP.balanceOf(livaOneAddress)).toString())

        // //Change Protocol
        // console.log("Vault active protocol", (await livaOne.getActiveProtocol(testVault.address)).toString())
        // let changeProtocolInstruction = abi.simpleEncode("changeProtocol(address)", crvUSDN.address).toString('hex');
        // console.log("Instruction \n", changeProtocolInstruction)
        // await livaOneMinter.mintStrategy(testVault.address, changeProtocolInstruction)
        // console.log("Vault active protocol after protocol change", (await livaOne.getActiveProtocol(testVault.address)).toString())
        // console.log("livaOne NAV after protocol change", (await livaOne.getStrategyNAV()).toString())
        // console.log("livaOne token value after protocol change", web3.utils.fromWei((await livaOne.tokenValueInUSD()).toString(), "ether"))
        // console.log("livaOne token vault balance after protocol change", (await livaOne.balanceOf(testVault.address)).toString())
        // console.log("livaOne crvUSDP tokens after protocol change", (await crvUSDP.balanceOf(livaOneAddress)).toString())
        // console.log("livaOne crvUSDN tokens after protocol change", (await crvUSDN.balanceOf(livaOneAddress)).toString())

        // //Withdraw from Strategy
        // console.log("usdt in Vault", (await usdt.balanceOf(testVault.address)).toString())
        // let withdrawInstruction = abi.simpleEncode("withdraw(uint256,address)", 50, usdt.address).toString('hex');
        // console.log("Instruction \n", withdrawInstruction)
        // await livaOneMinter.mintStrategy(testVault.address, withdrawInstruction)
        // console.log("livaOne NAV after strategy withdraw", (await livaOne.getStrategyNAV()).toString())
        // console.log("livaOne token value after strategy withdraw", web3.utils.fromWei((await livaOne.tokenValueInUSD()).toString(), "ether"))
        // console.log("livaOne token vault balance after strategy withdraw", (await livaOne.balanceOf(testVault.address)).toString())
        // console.log("livaOne crvUSDP tokens after strategy withdraw", (await crvUSDP.balanceOf(livaOneAddress)).toString())
        // console.log("livaOne crvUSDN tokens after strategy withdraw", (await crvUSDN.balanceOf(livaOneAddress)).toString())
        // console.log("usdt in Vault after strategy withdraw", (await usdt.balanceOf(testVault.address)).toString())
    });
});

const utils = require("./utils/general");
const ERC20 = artifacts.require("IERC20")
const APContract = artifacts.require("./aps/APContract.sol");
const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const ConvexSingleAssetStrategy = artifacts.require("./strategies/ConvexSingleAsset/ConvexCRV.sol");
const ConvexSingleAssetStrategyMinter = artifacts.require("./strategies/ConvexSingleAsset/ConvexCRVMinter.sol");

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
    let dai, usdc, usdt, busd, usdn;
    let uCrvUSDPToken, uCrvUSDNToken, uCrvBUSDToken, uCrvALUSDToken, uCrvLUSDToken, uCrvFRAXToken;
    let crvUSDP, crvUSDN, crvALUSD, crvLUSD, crvBUSD, crvFRAX, crv3;
    let proxyFactory, apContract;
    let yieldsterVaultMasterCopy;
    let singleAsset3Crv, singleAsset3CrvMinter;

    beforeEach(async function () {

        //---------------------------------CREATING-TOKENS-OBJECT-------------------------------------------//
        usdt = await ERC20.at("0xdac17f958d2ee523a2206206994597c13d831ec7")
        usdn = await ERC20.at("0x674C6Ad92Fd080e4004b2312b45f796a192D27a0")
        usdc = await ERC20.at("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
        frax = await ERC20.at("0x853d955acef822db058eb8505911ed77f175b99e")
        uCrvUSDNToken = await ERC20.at("0x4f3E8F405CF5aFC05D68142F3783bDfE13811522")
        crv3 = await ERC20.at("0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490")
        //---------------------------END--CREATING-TOKENS-OBJECT--------------------------------------------//

        //-----------------------BEGIN--TOKEN-TRANSFER------------------------------------------------------//
        await usdt.transfer(accounts[1], to6("10000"))
        await usdc.transfer(accounts[1], to6("10000"))
        await usdn.transfer(accounts[1], to18("10000"))
        await frax.transfer(accounts[1], to18("10000"))
        await uCrvUSDNToken.transfer(accounts[1], to18("10000"))
        await crv3.transfer(accounts[1], to18("10000"))
        //-------------------------END--TOKEN-TRANSFER------------------------------------------------------//


        apContract = await APContract.deployed();
        singleAsset3Crv = await ConvexSingleAssetStrategy.deployed()
        singleAsset3CrvMinter = await ConvexSingleAssetStrategyMinter.deployed()
        yieldsterVaultMasterCopy = await YieldsterVault.deployed()
        proxyFactory = await ProxyFactory.deployed()

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
            "vault address",
            testVault.address
        );

        console.log("Register Vault with APS")
        await testVault.registerVaultWithAPS();

        console.log("Set Vault Assets")
        await testVault.setVaultAssets(
            [usdt.address, usdn.address,usdc.address,frax.address,uCrvUSDNToken.address,crv3.address],
            [usdt.address, usdn.address,usdc.address,frax.address,uCrvUSDNToken.address,crv3.address],
            [],
            [],
        );

        console.log("set vault strategy and protocol")
        await testVault.setVaultStrategyAndProtocol(
            singleAsset3Crv.address,
            [
                "0xF403C135812408BFbE8713b5A23a04b3D48AAE31",
            ],
            [], []
        )


        //approve Tokens to vault
        await usdt.approve(testVault.address, to6("10000"), { from: accounts[1] })
        await usdc.approve(testVault.address, to6("10000"), { from: accounts[1] })
        await usdn.approve(testVault.address, to18("10000"), { from: accounts[1] })
        await frax.approve(testVault.address, to18("10000"), { from: accounts[1] })
        await uCrvUSDNToken.approve(testVault.address, to18("10000"), { from: accounts[1] })
        await crv3.approve(testVault.address, to18("10000"), { from: accounts[1] })

        console.log("Activating vault strategy ", singleAsset3Crv.address)
        await testVault.setVaultActiveStrategy(singleAsset3Crv.address)
        console.log("Vault active strategies", (await testVault.getVaultActiveStrategy()))


        // Deposit to vault
        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        console.log("usdt in User =", from6((await usdt.balanceOf(accounts[1])).toString()))
        console.log("usdt in Vault =", from6((await usdt.balanceOf(testVault.address)).toString()))
        console.log("usdn in User =", from18((await usdn.balanceOf(accounts[1])).toString()))
        console.log("usdn in Vault =", from18((await usdn.balanceOf(testVault.address)).toString()))


        //*****************************************************DEPOSIT**BEGINS***************************************************** */            
        console.log("===========================DEPOSIT=============================")
        await testVault.deposit(usdt.address, to6("10000"), { from: accounts[1] });
        await testVault.deposit(usdc.address, to6("10000"), { from: accounts[1] });
        // await testVault.deposit(usdn.address, to18("10000"), { from: accounts[1] });
        // await testVault.deposit(frax.address, to18("10000"), { from: accounts[1] });
        // await testVault.deposit(uCrvUSDNToken.address, to18("10000"), { from: accounts[1] });
        // await testVault.deposit(crv3.address, to18("10000"), { from: accounts[1] });
        //*****************************************************DEPOSIT**ENDS******************************************************* */            


        console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())
        console.log("usdt in User =", from6((await usdt.balanceOf(accounts[1])).toString()))
        console.log("usdt in Vault =", from6((await usdt.balanceOf(testVault.address)).toString()))
        console.log("usdc in User =", from6((await usdt.balanceOf(accounts[1])).toString()))
        console.log("usdc in Vault =", from6((await usdt.balanceOf(testVault.address)).toString()))
        console.log("usdn in User =", from18((await usdn.balanceOf(accounts[1])).toString()))
        console.log("usdn in Vault =", from18((await usdn.balanceOf(testVault.address)).toString()))
        console.log("crvUSDN in User =", from18((await uCrvUSDNToken.balanceOf(accounts[1])).toString()))
        console.log("crvUSDN in Vault =", from18((await uCrvUSDNToken.balanceOf(testVault.address)).toString()))
        console.log("frax in User =", from18((await frax.balanceOf(accounts[1])).toString()))
        console.log("frax in Vault =", from18((await frax.balanceOf(testVault.address)).toString()))
        console.log("crv3 in User =", from18((await crv3.balanceOf(accounts[1])).toString()))
        console.log("crv3 in Vault =", from18((await crv3.balanceOf(testVault.address)).toString()))
        
        //Deposit into strategy
        // console.log("singleAsset3Crv NAV =", from18((await singleAsset3Crv.getStrategyNAV()).toString()))
        // console.log("singleAsset3Crv token value =", from18((await singleAsset3Crv.tokenValueInUSD()).toString()))
        // console.log("singleAsset3Crv token vault balance =", from18((await singleAsset3Crv.balanceOf(testVault.address)).toString()))
        // console.log("singleAsset3Crv crvFRAX tokens  =", from18((await crvFRAX.balanceOf(singleAsset3Crv.address)).toString()))
        // console.log("===================STRATEGY DEPOSIT=====================")
        // let earnInstruction =
        //     web3.eth.abi.encodeParameters(['address[3]', 'uint256[3]', 'uint256', 'address[]', 'uint256[]'], [["0x6B175474E89094C44Da98b954EedeAC495271d0F", "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", "0xdac17f958d2ee523a2206206994597c13d831ec7"], [`${to18("0")}`, `${to6("0")}`, `${to6("20000")}`], "1", ["0x674C6Ad92Fd080e4004b2312b45f796a192D27a0"], [`${to18("10000")}`]]);

        // await singleAsset3CrvMinter.earn(testVault.address, [usdt.address, usdn.address], [to6("20000"), to18("10000")], earnInstruction)
        // console.log("singleAsset3Crv NAV =", from18((await singleAsset3Crv.getStrategyNAV()).toString()))
        // console.log("singleAsset3Crv token value =", from18((await singleAsset3Crv.tokenValueInUSD()).toString()))
        // console.log("singleAsset3Crv token vault balance =", from18((await singleAsset3Crv.balanceOf(testVault.address)).toString()))
        // console.log("singleAsset3Crv crvFRAX tokens  =", from18((await crvFRAX.balanceOf(singleAsset3Crv.address)).toString()))
        // console.log("Vault NAV =", from18(await testVault.getVaultNAV()).toString())
        // console.log("Vault Token Value =", from18(await testVault.tokenValueInUSD()).toString())

        // //Withdraw from Strategy
        // console.log("====================STRATEGY WITHDRAW===================================")
        // console.log("dai in Vault", from18((await dai.balanceOf(testVault.address)).toString()))
        // console.log("usdc in Vault", from6((await usdc.balanceOf(testVault.address)).toString()))
        // console.log("usdt in Vault", from6((await usdt.balanceOf(testVault.address)).toString()))
        // console.log("usdn in Vault", from18((await usdn.balanceOf(testVault.address)).toString()))
        // console.log("crv3 in Vault", from18((await crv3.balanceOf(testVault.address)).toString()))
        // console.log("uCrvFRAXToken in Vault", from18((await uCrvFRAXToken.balanceOf(testVault.address)).toString()))

        // let withdrawInstructionBytes = web3.eth.abi.encodeFunctionCall({
        //     name: 'withdraw',
        //     type: 'function',
        //     inputs: [{
        //         type: 'uint256',
        //         name: '_shares'
        //     }, {
        //         type: 'address',
        //         name: '_withrawalAsset'
        //     }
        //     ]
        // }, [to18("100"), dai.address])
        // console.log("Instruction \n", withdrawInstructionBytes)
        // await singleAsset3CrvMinter.mintStrategy(testVault.address, withdrawInstructionBytes)
        // console.log("singleAsset3Crv NAV after strategy withdraw", from18((await singleAsset3Crv.getStrategyNAV()).toString()))
        // console.log("singleAsset3Crv token value after strategy withdraw", from18((await singleAsset3Crv.tokenValueInUSD()).toString()))
        // console.log("singleAsset3Crv token vault balance after strategy withdraw", from18((await singleAsset3Crv.balanceOf(testVault.address)).toString()))
        // console.log("singleAsset3Crv crvFRAX tokens after strategy withdraw", from18((await crvFRAX.balanceOf(singleAsset3Crv.address)).toString()))
        // console.log("dai in Vault after strategy withdraw", from18((await dai.balanceOf(testVault.address)).toString()))
        // console.log("usdc in Vault after strategy withdraw", from6((await usdc.balanceOf(testVault.address)).toString()))
        // console.log("usdt in Vault after strategy withdraw", from6((await usdt.balanceOf(testVault.address)).toString()))
        // console.log("usdn in Vault after strategy withdraw", from18((await usdn.balanceOf(testVault.address)).toString()))
        // console.log("crv3 in Vault after strategy withdraw", from18((await crv3.balanceOf(testVault.address)).toString()))
        // console.log("uCrvFRAXToken in Vault after strategy withdraw", from18((await uCrvFRAXToken.balanceOf(testVault.address)).toString()))


        // //Withdraw from vault 
        // console.log("===========================WITHDRAW=============================")
        // console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        // console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())
        // console.log("dai in User ", from18(await dai.balanceOf(accounts[1])).toString())
        // console.log("dai in Vault ", from18((await dai.balanceOf(testVault.address)).toString()))
        // console.log("usdc in User ", from6((await usdc.balanceOf(accounts[1])).toString()))
        // console.log("usdc in Vault ", from6((await usdc.balanceOf(testVault.address)).toString()))
        // console.log("usdt in User", from6((await usdt.balanceOf(accounts[1])).toString()))
        // console.log("usdt in Vault", from6((await usdt.balanceOf(testVault.address)).toString()))
        // console.log("usdn in User ", from18((await usdn.balanceOf(accounts[1])).toString()))
        // console.log("usdn in Vault ", from18((await usdn.balanceOf(testVault.address)).toString()))
        // console.log("crv3 in User ", from18((await crv3.balanceOf(accounts[1])).toString()))
        // console.log("crv3 in Vault ", from18((await crv3.balanceOf(testVault.address)).toString()))
        // console.log("crvFRAX in User ", from18((await crvFRAX.balanceOf(accounts[1])).toString()))
        // console.log("crvFRAX in Vault ", from18((await crvFRAX.balanceOf(testVault.address)).toString()))
        // console.log("=================================================================")
        // await testVault.withdraw(uCrvFRAXToken.address, (await testVault.balanceOf(accounts[1])).toString(), { from: accounts[1], gas: 10000000 });
        // // await testVault.withdraw(usdt.address, to18("200"), { from: accounts[1], gas: 10000000 });
        // console.log("Vault NAV", from18(await testVault.getVaultNAV()).toString())
        // console.log("Vault Token Value", from18(await testVault.tokenValueInUSD()).toString())
        // console.log("dai in User ", from18(await dai.balanceOf(accounts[1])).toString())
        // console.log("dai in Vault ", from18((await dai.balanceOf(testVault.address)).toString()))
        // console.log("usdc in User ", from6((await usdc.balanceOf(accounts[1])).toString()))
        // console.log("usdc in Vault ", from6((await usdc.balanceOf(testVault.address)).toString()))
        // console.log("usdt in User", from6((await usdt.balanceOf(accounts[1])).toString()))
        // console.log("usdt in Vault", from6((await usdt.balanceOf(testVault.address)).toString()))
        // console.log("usdn in User ", from18((await usdn.balanceOf(accounts[1])).toString()))
        // console.log("usdn in Vault ", from18((await usdn.balanceOf(testVault.address)).toString()))
        // console.log("crv3 in User ", from18((await crv3.balanceOf(accounts[1])).toString()))
        // console.log("crv3 in Vault ", from18((await crv3.balanceOf(testVault.address)).toString()))
        // console.log("busd in User ", from18((await busd.balanceOf(accounts[1])).toString()))
        // console.log("busd in Vault ", from18((await busd.balanceOf(testVault.address)).toString()))
        // console.log("crvFRAX in User ", from18((await crvFRAX.balanceOf(accounts[1])).toString()))
        // console.log("crvFRAX in Vault ", from18((await crvFRAX.balanceOf(testVault.address)).toString()))
    });

});

/**

  let strat = await IERC20.at("0xEeee1F4CFE0bF372cF0C92F8D7509f97112fCEc7")

 let usdt = await ERC20.at("0xdac17f958d2ee523a2206206994597c13d831ec7")
 let usdn = await ERC20.at("0x674C6Ad92Fd080e4004b2312b45f796a192D27a0")
 let vault = await YieldsterVault.at("0x150a1763f6A8C6Cd79C225aAAa09344d64420B4D")
 let strategy = await ConvexCRV.at("0xEeee1F4CFE0bF372cF0C92F8D7509f97112fCEc7")   

 let rewardscontract= await IRewards.at("0x4a2631d090e8b40bBDe245e687BF09e5e534A239")  
 (await vault.getVaultNAV()).toString() / (10**18)
 */
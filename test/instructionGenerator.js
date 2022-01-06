const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider("ws://localhost:8545"));

const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";

const FRAX = "0x853d955acef822db058eb8505911ed77f175b99e";
const crvUSDN = "0x4f3E8F405CF5aFC05D68142F3783bDfE13811522";
const crv3 = "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490";
const USDN = "0x674C6Ad92Fd080e4004b2312b45f796a192D27a0";

(async () => {
    let assetsArr = [DAI, USDC, USDT, FRAX, crvUSDN, crv3, USDN];
    let assetsBal = ['0', '1000000000', '1000000000', '1000000000000000000000', '1000000000000000000000', '1000000000000000000000', '1000000000000000000000']
    const assetMapping = new Map();

    [].forEach(element => {
        assetMapping.set(assetsArr[element], assetsBal[element])
    })
    console.log(assetMapping)
    let dataParams = web3.eth.abi.encodeParameters(
        ['address[3]', 'uint256[3]', 'uint256', 'address[]', 'uint256[]'],
        [
            [DAI, USDC, USDT],
            ['0', '1000000000', '1000000000'],
            '1',
            [],
            []
            // [...assetMapping.keys()],
            // [...assetMapping.values()]
        ]
    )
    console.log(dataParams)
});

(async () => {
    let withdrawInstructionBytes = web3.eth.abi.encodeFunctionCall({
        name: 'withdraw',
        type: 'function',
        inputs: [{
            type: 'uint256',
            name: '_shares'
        }, {
            type: 'address',
            name: '_withrawalAsset'
        }
        ]
    }, ["3000000000000000000000", "0x674C6Ad92Fd080e4004b2312b45f796a192D27a0"])
    console.log("Instruction \n", withdrawInstructionBytes)
});

(async () => {
    // await testVault.withdraw(uCrvFRAXToken.address, (await testVault.balanceOf(accounts[1])).toString(), { from: accounts[1], gas: 10,000,000 });
    await vault.withdraw("0x4f3E8F405CF5aFC05D68142F3783bDfE13811522", "40000000000000000000000", { from: "0x9AD09ff288ef06E4cF8E51cF733c4cd8c5231109", gas: 30000000 })
    await vault.withdraw("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", "18500000000000000000000", { from: "0x9AD09ff288ef06E4cF8E51cF733c4cd8c5231109", gas: 70000000 })

    //9000000000000000000000
});

(async () => {
    let paybackExecutorInstruction = web3.eth.abi.encodeFunctionCall({
        name: 'paybackExecutor',
        type: 'function',
        inputs: [{
            type: 'uint256',
            name: 'gasCost'
        },
        {
            type: 'address',
            name: 'beneficiary'
        }]
    }, ["100000000000000000", "0x5091aF48BEB623b3DA0A53F726db63E13Ff91df9"])
    console.log(paybackExecutorInstruction)
});
/**
 let vault = await YieldsterVault.at("0xCEC4EB6db417C0D9B287cba0Bc34cdfE0d7d861E")
 let strategy = await ConvexCRV.at("0xd5147E19723fa46B97977848ff4DA0d3f4bdAbc0")
 let minter = await ConvexCRVMinter.at("0x45805aD1640D19F8fc509FBDCA77125df0aF8363")
 await minter.earn(vault.address,["0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48","0xdAC17F958D2ee523a2206206994597C13D831ec7"],["1000000000","1000000000"],"0x0000000000000000000000006b175474e89094c44da98b954eedeac495271d0f000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003b9aca00000000000000000000000000000000000000000000000000000000003b9aca0000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")

await minter.executeStrategyInstruction("0xe2625cfa000000000000000000000000000000000000000000000000016345785d8a00000000000000000000000000005091af48beb623b3da0a53f726db63e13ff91df9")

await strategy.setSlippage(5000)
await strategy.setSlippageSwap(5000)

(await vault.getVaultNAV()).toString() / (10**18) //20003.4578
(await vault.getVaultNAVWithoutStrategyToken()).toString() / (10**18)
(await strategy.getConvexBalance()).toString() /(10**18)

 (await usdn.balanceOf(vault.address)).toString() /(10**18)


 let crvUSDN = await ERC20.at("0x4f3E8F405CF5aFC05D68142F3783bDfE13811522")
 let crv3 = await ERC20.at("0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490")
 let USDN = await ERC20.at("0x674C6Ad92Fd080e4004b2312b45f796a192D27a0")
 let cvx = await ERC20.at("0x4e3fbd56cd56c3e72c1403e103b45db9da5b9d2b")
 let crv= await ERC20.at("0xD533a949740bb3306d119CC777fa900bA034cd52")
 (await cvx.balanceOf(accounts[1])).toString() /(10**18)


 (await crvUSDN.balanceOf(accounts[0])).toString() /(10**18)
 (await frax.balanceOf(accounts[1])).toString() /(10**18)

let strategyTokenPrice = await strategy.tokenValueInUSD()

(await strategy.getConvexBalance()).toString() /(10**18) //1934.6000260836597
(await vault.getVaultNAV()).toString() /(10**18) //20028.68122680535

*/
const APContract = artifacts.require("./aps/APContract.sol");
const ConvexCRV = artifacts.require("./strategies/ConvexSingleAsset/ConvexCRV.sol");
const ConvexCRVMinter = artifacts.require("./strategies/ConvexSingleAsset/ConvexCRVMinter.sol");

module.exports = async (deployer, network, accounts) => {
    const apContract = await APContract.deployed();

    //Deploy Single Asset Convex CRV 
    await deployer.deploy(ConvexCRV,
        "USDN CVX Strategy",
        "USDN-CVX",
        apContract.address,
        "13",
        "0x674C6Ad92Fd080e4004b2312b45f796a192D27a0"
    );

    const cvxUSDN = await ConvexCRV.deployed()
    await deployer.deploy(ConvexCRVMinter, apContract.address, cvxUSDN.address)

    const convexCRVMinter = await ConvexCRVMinter.deployed()

    await apContract.addStrategy(
        "CVX Strategy",
        cvxUSDN.address,
        [
            "0xB4AdA607B9d6b2c9Ee07A275e9616B84AC560139",
        ],
        convexCRVMinter.address,
        accounts[0],
        accounts[0],
        "0"
    );

    console.log(`CVX USDN :- ${cvxUSDN.address}`);
    console.log(`CVX USDN Minter :- ${convexCRVMinter.address}`);
    
};

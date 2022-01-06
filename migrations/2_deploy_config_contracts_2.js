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
            "0xF403C135812408BFbE8713b5A23a04b3D48AAE31",
        ],
        convexCRVMinter.address,
        accounts[0],
        accounts[0],
        "0"
    );

    console.log(`CVX USDN :- ${cvxUSDN.address}`);
    console.log(`CVX USDN Minter :- ${convexCRVMinter.address}`);
    
};

//APS Address :- 0xA84e51760332b6bB08EF275026828DA4fD836a22
// CVX USDN :- 0x2bd9D4621B302113F73C26c5fa4a5663e33551f3
// CVX USDN Minter :- 0x48a8F34e51467022be169a9DA5fD8B0c3eAA1B7C
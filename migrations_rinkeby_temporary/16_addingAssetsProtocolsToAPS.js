const APContract = artifacts.require("./aps/APContract.sol");


module.exports = async (deployer) => {
    const apContract = await APContract.deployed();

    console.log("Adding Assets")
    await apContract.addAsset(
        "DAI",
        "DAI Coin",
        "0x6B175474E89094C44Da98b954EedeAC495271d0F"
    );
    await apContract.addAsset(
        "USDC",
        "USD Coin",
        "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
    );
    await apContract.addAsset(
        "USDT",
        "USDT Coin",
        "0xdac17f958d2ee523a2206206994597c13d831ec7"
    );

    console.log("adding Protocols")
    await apContract.addProtocol(
        "yearn Curve.fi crvCOMP",
        "crvCOMP",
        "0x629c759D1E83eFbF63d84eb3868B564d9521C129"
    );
    await apContract.addProtocol(
        "yearn Curve.fi GUSD/3Crv",
        "crvGUSD",
        "0xcC7E70A958917cCe67B4B87a8C30E6297451aE98"
    );
    await apContract.addProtocol(
        "yearn Curve.fi yDAI/yUSDC/yUSDT/yBUSD",
        "crvBUSD",
        "0x2994529C0652D127b7842094103715ec5299bBed"
    );

};

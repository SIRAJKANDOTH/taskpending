const APContract = artifacts.require("./aps/APContract.sol");


module.exports = async (deployer) => {
    const apContract = await APContract.deployed();

    console.log("Adding Assets")
    await apContract.addAsset("DAI", "DAI Coin", "0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea")
    await apContract.addAsset("USDC", "USD Coin", "0x4dbcdf9b62e891a7cec5a2568c3f4faf9e8abe2b")
    await apContract.addAsset("LINK", "LINK Coin", "0x01be23585060835e02b77ef475b0cc51aa1e0709")

    console.log("adding Protocols")
    await apContract.addProtocol(
        "yearn Curve.fi crvCOMP",
        "crvCOMP",
        "0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8"
    );
    await apContract.addProtocol(
        "yearn Curve.fi GUSD/3Crv",
        "crvGUSD",
        "0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e"
    );
    await apContract.addProtocol(
        "yearn Curve.fi yDAI/yUSDC/yUSDT/yBUSD",
        "crvBUSD",
        "0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B"
    );

};

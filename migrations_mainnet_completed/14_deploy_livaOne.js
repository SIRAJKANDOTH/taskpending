const LivaOne = artifacts.require("./strategies/LivaOneZapper.sol");
// const APContract = artifacts.require("./aps/APContract.sol");



module.exports = async (deployer) => {
    // const apContract = await APContract.deployed();

    await deployer.deploy(LivaOne, "0xc078e9F3994bEf168e1aF3B2195A2C4149cc3f36", [
        "0x629c759D1E83eFbF63d84eb3868B564d9521C129",
        "0xcC7E70A958917cCe67B4B87a8C30E6297451aE98",
        "0x2994529C0652D127b7842094103715ec5299bBed",
    ]);


};
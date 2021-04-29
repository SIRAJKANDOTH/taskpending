const LivaOne = artifacts.require("./strategies/LivaOneZapper.sol");
const LivaOneMinter = artifacts.require("./strategies/LivaOneMinter.sol");
const APContract = artifacts.require("./aps/APContract.sol");



module.exports = async (deployer) => {
    // const apContract = await APContract.deployed();
    // const livaOne = await LivaOne.deployed();


    await deployer.deploy(LivaOneMinter, "0xc078e9F3994bEf168e1aF3B2195A2C4149cc3f36", "0x6c6C7dDBB2131dB09b6bA86B561147b0556a350d");
    // const livaOneMinter = await LivaOneMinter.deployed();

    // console.log("adding Liva one to APContract")
    // await apContract.addStrategy(
    //     "Liva One",
    //     livaOne.address,
    //     [
    //         "0x629c759D1E83eFbF63d84eb3868B564d9521C129",
    //         "0xcC7E70A958917cCe67B4B87a8C30E6297451aE98",
    //         "0x2994529C0652D127b7842094103715ec5299bBed",
    //     ],
    //     livaOneMinter.address,
    //     "0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0",
    //     "0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0",
    //     "2000000000000000"
    // );

};
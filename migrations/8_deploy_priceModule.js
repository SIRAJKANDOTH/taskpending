const PriceModule = artifacts.require("./price/PriceModule.sol");

module.exports = async (deployer) => {


    await deployer.deploy(
        PriceModule,
        "0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5"
    );


};

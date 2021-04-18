
const HexUtils = artifacts.require("./utils/HexUtils.sol");


module.exports = async (deployer) => {

    await deployer.deploy(HexUtils);


};

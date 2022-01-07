const SafeUtils = artifacts.require("./safeUtils/SafeUtils.sol");
const SafeMinter = artifacts.require("./safeUtils/SafeMinter.sol")

module.exports = async (deployer) =>{
    await deployer.deploy(SafeUtils);
    let safeUtils = await SafeUtils.deployed()
    console.log(`Safe utils deployed with address:- ${safeUtils.address}`);
    await deployer.deploy(SafeMinter)
    let safeMinter = await SafeMinter.deployed()
    console.log(`safe Minter deployed with address:- ${safeMinter.address}`);

}
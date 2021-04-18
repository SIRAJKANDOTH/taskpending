const SafeMinter = artifacts.require("./safeUtils/SafeMinter.sol")
const APContract = artifacts.require("./aps/APContract.sol");


module.exports = async (deployer) => {
    const apContract = await APContract.deployed();

    await deployer.deploy(
        SafeMinter,
        "0x5091aF48BEB623b3DA0A53F726db63E13Ff91df9"
    );
    const safeMinter = await SafeMinter.deployed();

    console.log("Adding safe minter to the APContract")
    await apContract.setSafeMinter(safeMinter.address);

};
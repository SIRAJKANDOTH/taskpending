const SafeMinter = artifacts.require("./safeUtils/SafeMinter.sol")
const APContract = artifacts.require("./aps/APContract.sol");


module.exports = async (deployer) => {
    const apContract = await APContract.deployed();

    await deployer.deploy(
        SafeMinter,
        "0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0"
    );
    const safeMinter = await SafeMinter.deployed();

    console.log("Adding safe minter to the APContract")
    await apContract.setSafeMinter(safeMinter.address);

};
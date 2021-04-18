const SafeMinter = artifacts.require("./safeUtils/SafeMinter.sol")
const APContract = artifacts.require("./aps/APContract.sol");


module.exports = async (deployer) => {
    const apContract = await APContract.deployed();

    await deployer.deploy(
        SafeMinter,
        accounts[0]
    );
    const safeMinter = await SafeMinter.deployed();

    console.log("Adding safe minter to the APContract")
    await apContract.setSafeMinter(safeMinter.address);

};
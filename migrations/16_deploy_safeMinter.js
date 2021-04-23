const SafeMinter = artifacts.require("./safeUtils/SafeMinter.sol")
const APContract = artifacts.require("./aps/APContract.sol");


module.exports = async (deployer) => {
    // const apContract = await APContract.deployed();

    await deployer.deploy(
        SafeMinter,
        "0x1D5dd498A70c379823BadF232779C04AA4b23c1D"
    );
    // const safeMinter = await SafeMinter.deployed();

    // console.log("Adding safe minter to the APContract")
    // await apContract.setSafeMinter(safeMinter.address);

};
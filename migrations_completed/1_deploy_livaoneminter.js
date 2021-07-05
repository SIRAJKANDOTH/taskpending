const LivaOneMinter = artifacts.require("LivaOneMinter");
const apContractAddress = "0xB24Ff34F5AE7F8Dde93A197FB406c1E78EEC0B25";
const livaOneAddress = "0x2747ce11793f7059567758cc35d34f63cee8ac00";
module.exports = async (deployer) => {
    await deployer.deploy(LivaOneMinter, apContractAddress, livaOneAddress);
};

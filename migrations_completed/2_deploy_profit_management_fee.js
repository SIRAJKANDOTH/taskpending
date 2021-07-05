const profitManagementFee = artifacts.require("ProfitManagementFee")

module.exports = async (deployer) => {
    await deployer.deploy(profitManagementFee);
};
const APContract = artifacts.require("./aps/APContract.sol");
const LivaOneMinter = artifacts.require("./strategies/LivaOneMinter.sol");

let livaOneAddress = "0x651aF6473dE9Bf97e4f489c3351956283A92d94b"
module.exports = async (deployer, network, accounts) => {
    const apContract = await APContract.deployed();
    
    await deployer.deploy(LivaOneMinter, apContract.address, livaOneAddress)
    const livaOneMinter = await LivaOneMinter.deployed()

    await apContract.addStrategy(
        "Liva One",
        livaOneAddress,
        [
            "0xC4dAf3b5e2A9e93861c3FBDd25f1e943B8D87417",
            "0x3B96d491f067912D18563d56858Ba7d6EC67a6fa",
            "0xA74d4B67b3368E83797a35382AFB776bAAE4F5C8",
            "0x5fA5B62c8AF877CB37031e0a3B2f34A78e3C56A6",
            "0x6Ede7F19df5df6EF23bD5B9CeDb651580Bdf56Ca",
        ],
        livaOneMinter.address,
        accounts[0],
        accounts[0],
        "2000000000000000"
    );

};

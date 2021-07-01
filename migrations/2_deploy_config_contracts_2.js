const APContract = artifacts.require("./aps/APContract.sol");
const LivaOne = artifacts.require("./strategies/LivaOne/LivaOneCrv.sol");
const LivaOneMinter = artifacts.require("./strategies/LivaOne/LivaOneMinter.sol");

module.exports = async (deployer, network, accounts) => {
    const apContract = await APContract.deployed();

    await deployer.deploy(LivaOne, apContract.address,
        [
            "0xC4dAf3b5e2A9e93861c3FBDd25f1e943B8D87417",
            "0x3B96d491f067912D18563d56858Ba7d6EC67a6fa",
            "0xA74d4B67b3368E83797a35382AFB776bAAE4F5C8",
            "0x5fA5B62c8AF877CB37031e0a3B2f34A78e3C56A6",
            "0x6Ede7F19df5df6EF23bD5B9CeDb651580Bdf56Ca",
        ]
    );

    const livaOne = await LivaOne.deployed()
    await deployer.deploy(LivaOneMinter, apContract.address, livaOne.address)

    const livaOneMinter = await LivaOneMinter.deployed()

    await apContract.addStrategy(
        "Liva One",
        livaOne.address,
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

const APContract = artifacts.require("./aps/APContract.sol");
const LivaOne = artifacts.require("./strategies/LivaOne/LivaOneCrv.sol");
const LivaOneMinter = artifacts.require("./strategies/LivaOne/LivaOneMinter.sol");
const EuroPlus = artifacts.require("./strategies/EuroPlus/EuroPlus.sol");
const EuroPlusMinter = artifacts.require("./strategies/EuroPlus/EuroPlusMinter.sol");
const SingleAsset3Crv = artifacts.require("./strategies/SingleAsset3Crv/SingleAsset3Crv.sol");
const SingleAsset3CrvMinter = artifacts.require("./strategies/SingleAsset3Crv/SingleAsset3CrvMinter.sol");

module.exports = async (deployer, network, accounts) => {
    const apContract = await APContract.deployed();

    // //Deploy Liva One
    // await deployer.deploy(LivaOne, apContract.address,
    //     [
    //         "0xC4dAf3b5e2A9e93861c3FBDd25f1e943B8D87417",
    //         "0x3B96d491f067912D18563d56858Ba7d6EC67a6fa",
    //         "0xA74d4B67b3368E83797a35382AFB776bAAE4F5C8",
    //         "0x5fA5B62c8AF877CB37031e0a3B2f34A78e3C56A6",
    //         "0x6Ede7F19df5df6EF23bD5B9CeDb651580Bdf56Ca",
    //     ]
    // );

    // const livaOne = await LivaOne.deployed()
    // await deployer.deploy(LivaOneMinter, apContract.address, livaOne.address)

    // const livaOneMinter = await LivaOneMinter.deployed()

    // await apContract.addStrategy(
    //     "Liva One",
    //     livaOne.address,
    //     [
    //         "0xC4dAf3b5e2A9e93861c3FBDd25f1e943B8D87417",
    //         "0x3B96d491f067912D18563d56858Ba7d6EC67a6fa",
    //         "0xA74d4B67b3368E83797a35382AFB776bAAE4F5C8",
    //         "0x6Ede7F19df5df6EF23bD5B9CeDb651580Bdf56Ca",
    //     ],
    //     livaOneMinter.address,
    //     accounts[0],
    //     accounts[0],
    //     "2000000000000000"
    // );

    //Deploy EuroPlus
    // await deployer.deploy(EuroPlus, apContract.address,
    //     "0x25212Df29073FfFA7A67399AcEfC2dd75a831A1A",
    //     [
    //         "0xdB25f211AB05b1c97D595516F45794528a807ad8",
    //         "0xD71eCFF9342A5Ced620049e616c5035F1dB98620",
    //     ]
    // );

    // const euroPlus = await EuroPlus.deployed()
    // await deployer.deploy(EuroPlusMinter, apContract.address, euroPlus.address)

    // const euroPlusMinter = await EuroPlusMinter.deployed()

    // await apContract.addStrategy(
    //     "Euro Plus",
    //     euroPlus.address,
    //     [
    //         "0x25212Df29073FfFA7A67399AcEfC2dd75a831A1A",
    //     ],
    //     euroPlusMinter.address,
    //     accounts[0],
    //     accounts[0],
    //     "0"
    // );

    //Deploy Singe Asset 3Crv
    await deployer.deploy(SingleAsset3Crv,
        "USDN",
        "USDN Strategy",
        apContract.address,
        "0x3B96d491f067912D18563d56858Ba7d6EC67a6fa",
        "0x674C6Ad92Fd080e4004b2312b45f796a192D27a0"
    );

    const singleAsset3Crv = await SingleAsset3Crv.deployed()
    await deployer.deploy(SingleAsset3CrvMinter, apContract.address, singleAsset3Crv.address)

    const singleAsset3CrvMinter = await SingleAsset3CrvMinter.deployed()

    await apContract.addStrategy(
        "Euro Plus",
        singleAsset3Crv.address,
        [
            "0x3B96d491f067912D18563d56858Ba7d6EC67a6fa",
        ],
        singleAsset3CrvMinter.address,
        accounts[0],
        accounts[0],
        "0"
    );

};

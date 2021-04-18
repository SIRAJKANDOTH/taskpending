const PriceModule = artifacts.require("./price/PriceModule.sol");

module.exports = async (deployer) => {


    await deployer.deploy(
        PriceModule,
        "0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5"
    );
    const priceModule = await PriceModule.deployed();

    await priceModule.addToken("0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea", "0x2bA49Aaa16E6afD2a993473cfB70Fa8559B523cF", '1')
    await priceModule.addToken("0x4dbcdf9b62e891a7cec5a2568c3f4faf9e8abe2b", "0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB", '1')
    await priceModule.addToken("0x01be23585060835e02b77ef475b0cc51aa1e0709", "0xd8bD0a1cB028a31AA859A21A3758685a95dE4623", '1')
    await priceModule.addToken("0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8", "0xd8bD0a1cB028a31AA859A21A3758685a95dE4623", '1')
    await priceModule.addToken("0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e", "0xd8bD0a1cB028a31AA859A21A3758685a95dE4623", '1')
    await priceModule.addToken("0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B", "0xd8bD0a1cB028a31AA859A21A3758685a95dE4623", '1')


};

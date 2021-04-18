const YieldsterVault = artifacts.require("./YieldsterVault.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const APContract = artifacts.require("./aps/APContract.sol");
const PriceModule = artifacts.require("./price/PriceModule.sol");
const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
const PlatformManagementFee = artifacts.require("./delegateContracts/ManagementFee.sol");
const ProfitManagementFee = artifacts.require("./delegateContracts/ProfitManagementFee.sol");
const YearnItAll = artifacts.require("./strategies/YearnItAllZapper.sol");
const LivaOne = artifacts.require("./strategies/LivaOneZapper.sol");
const YearnItAllMinter = artifacts.require("./strategies/YearnItAllMinter.sol");
const LivaOneMinter = artifacts.require("./strategies/LivaOneMinter.sol");
const HexUtils = artifacts.require("./utils/HexUtils.sol");
const StockDeposit = artifacts.require("./smartStrategies/deposit/StockDeposit.sol");
const StockWithdraw = artifacts.require("./smartStrategies/deposit/StockWithdraw.sol");
const Exchange = artifacts.require("./exchange/Exchange.sol");
const CleanUp = artifacts.require("./cleanUp/CleanUp.sol");
const OneInch = artifacts.require("./oneInchMock/OneInch.sol");

module.exports = async (deployer) => {
	await deployer.deploy(YieldsterVault);
	const yieldsterVaultMasterCopy = await YieldsterVault.deployed();

	await deployer.deploy(PlatformManagementFee);
	const managementFee = await PlatformManagementFee.deployed();

	await deployer.deploy(ProfitManagementFee);
	const profitManagementFee = await ProfitManagementFee.deployed();

	await deployer.deploy(Whitelist);
	const whitelist = await Whitelist.deployed();

	await deployer.deploy(HexUtils);
	const hexUtils = await HexUtils.deployed();

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

	await deployer.deploy(Exchange);
	const exchange = await Exchange.deployed();

	await deployer.deploy(CleanUp);
	const cleanUp = await CleanUp.deployed();

	await deployer.deploy(OneInch);
	const oneInch = await OneInch.deployed();

	await deployer.deploy(
		APContract,
		whitelist.address,
		managementFee.address,
		profitManagementFee.address,
		hexUtils.address,
		exchange.address,
		oneInch.address,
		priceModule.address,
		cleanUp.address
	);
	const apContract = await APContract.deployed();

	await deployer.deploy(StockDeposit);
	const stockDeposit = await StockDeposit.deployed();

	await deployer.deploy(StockWithdraw);
	const stockWithdraw = await StockWithdraw.deployed();

	//Deploying Proxy Factory
	await deployer.deploy(
		ProxyFactory,
		yieldsterVaultMasterCopy.address,
		apContract.address
	);
	const proxyFactory = await ProxyFactory.deployed();

	//Deploying Yearn It All strategy
	await deployer.deploy(YearnItAll, apContract.address, [
		"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
		"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
		"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
	]);
	const yearnItAll = await YearnItAll.deployed();
	await deployer.deploy(
		YearnItAllMinter,
		apContract.address,
		yearnItAll.address
	);
	const yearnItAllMinter = await YearnItAllMinter.deployed();

	//Deploying Liva One strategy
	await deployer.deploy(LivaOne, apContract.address, [
		"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
		"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
		"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
	]);
	const livaOne = await LivaOne.deployed();
	await deployer.deploy(LivaOneMinter, apContract.address, livaOne.address);
	const livaOneMinter = await LivaOneMinter.deployed();

	await apContract.setStockDepositWithdraw(
		stockDeposit.address,
		stockWithdraw.address
	);

	await apContract.addProxyFactory(proxyFactory.address);

	//adding assets
	await apContract.addAsset(
		"DAI",
		"DAI Coin",
		"0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea"
	);
	await apContract.addAsset(
		"USDC",
		"USD Coin",
		"0x4dbcdf9b62e891a7cec5a2568c3f4faf9e8abe2b"
	);
	await apContract.addAsset(
		"LINK",
		"LINK Coin",
		"0x01be23585060835e02b77ef475b0cc51aa1e0709"
	);

	//adding protocols
	await apContract.addProtocol(
		"yearn Curve.fi crvCOMP",
		"crvCOMP",
		"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8"
	);
	await apContract.addProtocol(
		"yearn Curve.fi GUSD/3Crv",
		"crvGUSD",
		"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e"
	);
	await apContract.addProtocol(
		"yearn Curve.fi MUSD/3Crv",
		"crvMUSD",
		"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B"
	);

	//adding strategy to AP contract
	await apContract.addStrategy(
		"Yearn it All",
		yearnItAll.address,
		[
			"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
			"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
			"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
		],
		yearnItAllMinter.address,
		"0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0",
		"0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0",
		"2000000000000000"
	);

	await apContract.addStrategy(
		"Liva One",
		livaOne.address,
		[
			"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
			"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
			"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
		],
		livaOneMinter.address,
		"0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0",
		"0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0",
		"2000000000000000"
	);
};

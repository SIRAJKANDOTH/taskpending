// const YieldsterVault = artifacts.require("./YieldsterVault.sol");
// const APContract = artifacts.require("./aps/APContract.sol");
// const ProxyFactory = artifacts.require("./proxies/YieldsterVaultProxyFactory.sol");
// const PlatformManagementFee = artifacts.require("./delegateContracts/ManagementFee.sol");
// const ProfitManagementFee = artifacts.require("./delegateContracts/ProfitManagementFee.sol");
// const YearnItAll = artifacts.require("./strategies/YearnItAllZapper.sol");
// const LivaOne = artifacts.require("./strategies/LivaOneZapper.sol");
// const YearnItAllMinter = artifacts.require("./strategies/YearnItAllMinter.sol");
// const LivaOneMinter = artifacts.require("./strategies/LivaOneMinter.sol");
// const HexUtils = artifacts.require("./utils/HexUtils.sol");
// const StockDeposit = artifacts.require("./smartStrategies/deposit/StockDeposit.sol");
// const StockWithdraw = artifacts.require("./smartStrategies/deposit/StockWithdraw.sol");
// const Exchange = artifacts.require("./exchange/Exchange.sol");
// const CleanUp = artifacts.require("./cleanUp/CleanUp.sol");

// module.exports = async (deployer) => {
	

// 	//Deploying all delegate contracts
// 	await deployer.deploy(PlatformManagementFee);
// 	const managementFee = await PlatformManagementFee.deployed();
	
// 	await deployer.deploy(ProfitManagementFee);
// 	const profitManagementFee = await ProfitManagementFee.deployed();
	
// 	await deployer.deploy(HexUtils);
// 	const hexUtils = await HexUtils.deployed();
	
// 	await deployer.deploy(Exchange);
// 	const exchange = await Exchange.deployed();
	
// 	await deployer.deploy(CleanUp);
// 	const cleanUp = await CleanUp.deployed();

// 	await deployer.deploy(YieldsterVault);
// 	const yieldsterVaultMasterCopy = await YieldsterVault.deployed();

// 	await deployer.deploy(
// 		APContract,
// 		"0xf8C992D12DC8a15e156869058717baC13d383F26",
// 		managementFee.address,
// 		profitManagementFee.address,
// 		hexUtils.address,
// 		exchange.address,
// 		"0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E",
// 		"0x7dF98189D32aa4e92649dBe5d837126bE4e53d1B",
// 		cleanUp.address
// 	);
// 	const apContract = await APContract.deployed();

// 	await deployer.deploy(StockDeposit);
// 	const stockDeposit = await StockDeposit.deployed();

// 	await deployer.deploy(StockWithdraw);
// 	const stockWithdraw = await StockWithdraw.deployed();

// 	//Deploying Proxy Factory
// 	await deployer.deploy(
// 		ProxyFactory,
// 		yieldsterVaultMasterCopy.address,
// 		apContract.address
// 	);
// 	const proxyFactory = await ProxyFactory.deployed();

// 	//Deploying Liva One strategy
// 	await deployer.deploy(LivaOne, apContract.address, [
// 		"0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
// 		"0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
// 		"0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
// 	]);
// 	const livaOne = await LivaOne.deployed();
// 	await deployer.deploy(LivaOneMinter, apContract.address, livaOne.address);
// 	const livaOneMinter = await LivaOneMinter.deployed();

// 	await apContract.setStockDepositWithdraw(
// 		stockDeposit.address,
// 		stockWithdraw.address
// 	);

// 	await apContract.addProxyFactory(proxyFactory.address);

// 	//adding assets
// 	await apContract.addAsset(
// 		"DAI",
// 		"DAI Coin",
// 		"0x6B175474E89094C44Da98b954EedeAC495271d0F"
// 	);
// 	await apContract.addAsset(
// 		"USDC",
// 		"USD Coin",
// 		"0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
// 	);
// 	await apContract.addAsset(
// 		"USDT",
// 		"USDT Coin",
// 		"0xdac17f958d2ee523a2206206994597c13d831ec7"
// 	);

// 	//adding protocols
// 	await apContract.addProtocol(
// 		"yearn Curve.fi crvCOMP",
// 		"crvCOMP",
// 		"0x629c759D1E83eFbF63d84eb3868B564d9521C129"
// 	);
// 	await apContract.addProtocol(
// 		"yearn Curve.fi GUSD/3Crv",
// 		"crvGUSD",
// 		"0xcC7E70A958917cCe67B4B87a8C30E6297451aE98"
// 	);
// 	await apContract.addProtocol(
// 		"yearn Curve.fi yDAI/yUSDC/yUSDT/yBUSD",
// 		"crvBUSD",
// 		"0x2994529C0652D127b7842094103715ec5299bBed"
// 	);

// 	//adding strategy to AP contract
// 	await apContract.addStrategy(
// 		"Liva One",
// 		livaOne.address,
// 		[
// 			"0x629c759D1E83eFbF63d84eb3868B564d9521C129",
// 			"0xcC7E70A958917cCe67B4B87a8C30E6297451aE98",
// 			"0x2994529C0652D127b7842094103715ec5299bBed",
// 		],
// 		livaOneMinter.address,
// 		"0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0",
// 		"0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0",
// 		"2000000000000000"
// 	);
// };

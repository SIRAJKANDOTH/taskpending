// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;


interface IAPContract{
    
    function isAssetPresent(address) external view returns(bool);

    function addAsset(string calldata ,string calldata ,address ,address ) external;

    function removeAsset(address ) external;
    
    function getAssetDetails(address ) external view returns(string memory,address ,string memory);

    function getUSDPrice(address ) external view returns(uint256);

    function addProtocol(string calldata ,string calldata ,address) external;

    function removeProtocol(address) external;

    function addVault(address, address, uint256[] calldata, address) external;

    function setVaultAssets(address[] calldata, address[] calldata,address[] calldata,address[] calldata) external;

    function createVault(address, address) external;

    function yieldsterDAO() view external returns(address);

    function yieldsterTreasury() view external returns(address);

    function yieldsterGOD() view external returns(address);

    function emergencyVault() external view returns(address);

    function yieldsterExchange() external view returns(address);

    function strategyExecutor() external view returns(address);

    function strategyMinter() external view returns(address);

    function stockDeposit() external view returns(address);
    
    function stockWithdraw() external view returns(address);

    function setYieldsterGOD(address) external;

    function getDepositStrategy() external returns(address);

    function getWithdrawStrategy() external returns(address);

    function changeVaultAPSManager(address) external;

    function setVaultStrategyAndProtocol(address , address[] calldata , address[] calldata, address[] calldata ) external;

    function setVaultActiveStrategy(address) external;

    function deactivateVaultStrategy(address ) external;
        
    function _isVaultAsset(address) external view returns(bool);

    function disableVaultStrategy(address, address[] calldata) external;

    function whitelistModule() view external returns(address);

    function isDepositAsset(address ) external view returns(bool);

    function isWithdrawalAsset(address ) external view returns(bool);

    function getConverter( address , address) external view returns(address);

    function getVaultActiveStrategy(address)external view returns(address);

    function _isStrategyProtocolEnabled(address, address, address) external view returns(bool);

    function _isStrategyEnabled( address , address )external view returns(bool);

    function getVaultManagementFee() external returns(address[] memory);

    function setVaultSmartStrategy(address, uint256) external;

    function stringUtils() external view returns(address);   
}
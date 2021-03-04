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

    function getYieldsterDAO() view external returns(address);

    function getYieldsterTreasury() view external returns(address);

    function getYieldsterGOD() view external returns(address);

    function getEmergencyVault() external view returns(address);

    function setYieldsterGOD(address) external;

    function changeVaultAPSManager(address) external;

    function setVaultStrategyAndProtocol(address , address[] calldata , address[] calldata, address[] calldata ) external;

    function setVaultActiveStrategy(address) external;

    function deactivateVaultStrategy(address ) external;
        
    function _isVaultAsset(address) external view returns(bool);

    function disableVaultStrategy(address, address[] calldata) external;

    function getwhitelistModule() view external returns(address);

    function isDepositAsset(address ) external view returns(bool);

    function isWithdrawalAsset(address ) external view returns(bool);

    function getConverter( address , address) external view returns(address);

    function getVaultActiveStrategy(address)external view returns(address);

    function _isStrategyProtocolEnabled(address, address, address) external view returns(bool);

    function _isStrategyEnabled( address , address )external view returns(bool);

    function getStrategyInstructionId(uint256) external returns(address);
    function platFormManagementFee() external view returns(address);
}
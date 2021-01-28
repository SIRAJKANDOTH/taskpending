// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;


interface IAPContract{
    
    function isAssetPresent(address) external view returns(bool);

    function addAsset(string calldata ,string calldata ,address ,address ) external;

    function removeAsset(address ) external;
    
    function getAssetDetails(address ) external view returns(string memory,address ,string memory);

    function getUSDPrice(address ) external returns(int,uint);

    function addProtocol(string calldata ,string calldata ,address) external;

    function removeProtocol(address) external;

    function addVault(address[] calldata, address[] calldata, address[] calldata, address, address, string[] calldata, address) external;

    function createVault(address, address) external;

    function getYieldsterDAO() view external returns(address);

    function changeVaultAPSManager(address) external;

    function setVaultStrategyAndProtocol(address _vaultStrategy, address[] calldata _strategyProtocols) external;

    function getwhitelistModule() view external returns(address);
}
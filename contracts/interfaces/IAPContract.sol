// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

interface IAPContract{
    
    function isAssetPresent(address) external view returns(bool);

    function addAsset(string calldata ,string calldata ,address ,address ) external;

    function removeAsset(address ) external;
    
    function getAssetDetails(address ) external view returns(string memory,address ,string memory);

    function getUSDPrice(address ) external returns(int,uint);

    function addProtocol(string calldata ,string calldata ,address) external;

    function removeProtocol(address) external;
}
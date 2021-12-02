pragma solidity ^0.5.0;

interface ITokenMinter{
   
    function totalSupply() external view returns(uint256);
    function reductionPerCliff() external view returns(uint256);
    function totalCliffs() external view returns(uint256);
    function maxSupply() external view returns(uint256);
    
}
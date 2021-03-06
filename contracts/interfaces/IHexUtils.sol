pragma solidity >=0.5.0 <0.7.0;

interface IHexUtils
{

    function fromHex(bytes calldata)  external  pure  returns(bytes memory);
    
    function fromHexChar(uint8 )  external  pure  returns(uint8);

    function toDecimals(address, uint256) external view returns (uint256);

    function fromDecimals(address, uint256)  external view returns (uint256);


}
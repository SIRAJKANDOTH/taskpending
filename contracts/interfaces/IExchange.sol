pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IExchange{
    function swap(address,address,uint256 ,uint256 ,uint256[] calldata,uint256 ) external payable returns(uint256);

    function getExpectedReturnWithGas(address,address,uint256,uint256,uint256,uint256)external view returns(
        uint256,
        uint256 ,
        uint256[] memory
    );
    function getExpectedReturn(address ,address ,uint256 ,uint256 ,uint256 ) external view returns(
        uint256 ,
        uint256[] memory 
    );
}
pragma solidity >=0.5.0 <0.7.0;

interface IExchange {
    function swap(
        address, //from
        address, //to
        uint256, //amount
        uint256 //minAmount
    ) external returns (uint256);
}

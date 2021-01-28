pragma solidity >=0.5.0 <0.7.0;

interface ISmartLender {
    function handleLoanRequest(address,uint256,address) external;
}
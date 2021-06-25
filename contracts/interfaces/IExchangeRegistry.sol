pragma solidity >=0.5.0 <0.7.0;

interface IExchangeRegistry {
    function getPair(address, address) external returns (address);
}

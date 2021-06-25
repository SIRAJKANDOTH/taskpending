pragma solidity >=0.5.0 <0.7.0;

interface IWhitelist {
    function isMember(uint256, address) external view returns (bool);
}

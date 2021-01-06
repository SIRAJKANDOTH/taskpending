pragma solidity >=0.5.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract yrToken is ERC20 {
    constructor(uint256 initialSupply) public {
        _mint(msg.sender, initialSupply);  // Create initial supply
    }
}

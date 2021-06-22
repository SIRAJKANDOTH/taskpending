pragma solidity >=0.5.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract uCrvBUSD is ERC20, ERC20Detailed {
    constructor() public ERC20Detailed("uCrvBUSD", "uCrvBUSD Token", 18) {
        _mint(msg.sender, 1e18 * 1e18);
    }
}

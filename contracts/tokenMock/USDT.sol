pragma solidity >=0.5.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20, ERC20Detailed {
    constructor() public ERC20Detailed("USDT", "USDT Token", 6) {
        _mint(msg.sender, 1e18 * 1e18);
    }
}

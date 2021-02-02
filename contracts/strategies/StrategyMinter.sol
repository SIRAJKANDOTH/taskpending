pragma solidity >=0.5.0 <0.8.0;
// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../token/ERC1155/ERC1155.sol";

contract StrategyMinter is ERC1155{
    uint256 public constant ENABLE = 0;
    uint256 public constant CHANGE_PROTOCOL = 1;
    uint256 public constant DISABLE = 2;
    uint256 public constant LOCK = 3;
    constructor() public ERC1155("https://game.example/api/item/{id}.json") {
    }

// test purpose
    function mintStrategy(address safeAddress) public{
        _mint(safeAddress, 5, 10**18, "_mint(tx.origin, 100);");
    }
}
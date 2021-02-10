pragma solidity >=0.5.0 <0.8.0;
// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../token/ERC1155/ERC1155.sol";

contract StrategyMinter is ERC1155{
    uint256 public constant SAFE_INSTRUCTION = 0;
    uint256 public constant STRATEGY_INSTRUCTION = 1;

    constructor() public ERC1155("https://game.example/api/item/{id}.json") {
    }
    function mintStrategy(address safeAddress,string memory instruction, uint256 instruction_type) public{
        require(instruction_type==SAFE_INSTRUCTION||instruction_type==STRATEGY_INSTRUCTION,"Invalid instruction type!");
        _mint(safeAddress, instruction_type, 10**18, bytes(instruction));
    }
}
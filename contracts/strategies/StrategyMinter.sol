pragma solidity >=0.5.0 <0.8.0;
// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../token/ERC1155/ERC1155.sol";

contract StrategyMinter is ERC1155
{
    constructor() public ERC1155("https://game.example/api/item/{id}.json") 
    {}

    function mintStrategy(
        address safeAddress,
        string memory instruction, 
        uint256 instruction_type
        ) 
        public
    {
        _mint(safeAddress, instruction_type, 10**18, bytes(instruction));
    }
}
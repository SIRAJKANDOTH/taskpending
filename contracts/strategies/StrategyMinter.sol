pragma solidity >=0.5.0 <0.8.0;
import "../token/ERC1155/ERC1155.sol";
import "../interfaces/IAPContract.sol";

contract StrategyMinter is ERC1155
{
    address public APContract;
    constructor(address _APContract) public ERC1155("https://game.example/api/item/{id}.json") 
    {
        APContract = _APContract;
    }

    function mintStrategy(
        address safeAddress,
        string memory instruction, 
        uint256 instruction_type
        ) 
        public
    {
        require(IAPContract(APContract).strategyExecutor() == msg.sender, "Only Yieldster Strategy Executor");
        _mint(safeAddress, instruction_type, 10**18, bytes(instruction));
    }
}
pragma solidity >=0.5.0 <0.8.0;
import "../token/ERC1155/ERC1155.sol";
import "../interfaces/IAPContract.sol";

contract WithdrawalLockMinter is ERC1155
{
    address public APContract;
        address private strategy;
        address private owner;
        address private executor;

    constructor(address _APContract,address _strategyAddress) public ERC1155("https://game.example/api/item/{id}.json") 
    {
        APContract = _APContract;
        strategy=_strategyAddress;
        owner=msg.sender;
        executor=msg.sender;
    }

    modifier onlyOwner{
        require(owner==msg.sender,"Not permitted");
        _;
    }

    function mintStrategy(
        address safeAddress,
        string memory instruction, 
        uint256 instruction_type
        ) 
        public
    {
        require(IAPContract(APContract).strategyExecutor(strategy) == msg.sender, "Not a approved executer");
        _mint(safeAddress, instruction_type, 10**18, bytes(instruction));
    }


    function setExecutor(address _executor) public onlyOwner{
        executor=_executor;

    }


}
pragma solidity >=0.5.0 <0.8.0;
import "../../token/ERC1155/ERC1155.sol";
import "../../interfaces/IAPContract.sol";
import "../../interfaces/IYieldsterVault.sol";

contract EuroPlusMinter is ERC1155 {
    address public APContract;
    address public strategy;
    address public owner;

    constructor(address _APContract, address _strategyAddress)
        public
        ERC1155("https://yieldster.finance/strategy/meta/{id}.json")
    {
        APContract = _APContract;
        strategy = _strategyAddress;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only permitted to owner");
        _;
    }

    function setAPContract(address _APContract) public onlyOwner {
        APContract = _APContract;
    }

    function setStrategyAddress(address _strategyAddress) public onlyOwner {
        strategy = _strategyAddress;
    }

    function mintStrategy(address safeAddress, bytes memory instruction)
        public
    {
        require(
            IAPContract(APContract).strategyExecutor(strategy) == msg.sender,
            "Only Yieldster Strategy Executor"
        );
        _mint(safeAddress, 1, 10**18, instruction);
    }

    function earn(
        address safeAddress,
        address[] memory _assets,
        uint256[] memory _amount,
        bytes memory data
    ) public {
        require(
            IAPContract(APContract).strategyExecutor(strategy) == msg.sender,
            "Only Yieldster Strategy Executor"
        );
        IYieldsterVault(safeAddress).earn(_assets, _amount, data);
    }
}

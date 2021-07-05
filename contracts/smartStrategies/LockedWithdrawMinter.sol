pragma solidity >=0.5.0 <0.8.0;
import "../token/ERC1155/ERC1155.sol";
import "../interfaces/IAPContract.sol";

contract LockedWithdrawMinter is ERC1155 {
    address public APContract;
    address private strategy;

    constructor(address _APContract, address _strategyAddress)
        public
        ERC1155("https://yieldster.finance/strategy/meta/{id}.json")
    {
        APContract = _APContract;
        strategy = _strategyAddress;
    }

    function mintStrategy(address safeAddress, string memory instruction)
        public
    {
        require(
            IAPContract(APContract).smartStrategyExecutor(strategy) ==
                msg.sender,
            "Not a approved executer"
        );
        _mint(safeAddress, 3, 10**18, bytes(instruction));
    }
}

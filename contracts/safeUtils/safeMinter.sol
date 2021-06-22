pragma solidity >=0.5.0 <0.8.0;
import "../token/ERC1155/ERC1155.sol";
import "../interfaces/IAPContract.sol";

contract SafeMinter is ERC1155 {
    address public owner;
    address public executor;

    constructor(address _executor)
        public
        ERC1155("https://yieldster.finance/vault/meta/{id}.json")
    {
        owner = msg.sender;
        executor = _executor;
    }

    function mintStrategy(address safeAddress, string memory instruction)
        public
    {
        require(executor == msg.sender, "Not Authorized");
        _mint(safeAddress, 0, 10**18, bytes(instruction));
    }

    function setExecutor(address _executor) public {
        require(msg.sender == owner, "Not Authorized");
        executor = _executor;
    }
}

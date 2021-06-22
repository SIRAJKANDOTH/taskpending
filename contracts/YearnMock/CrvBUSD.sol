pragma solidity >=0.5.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract CrvBUSD is ERC20, ERC20Detailed {
    using Address for address;
    using SafeMath for uint256;
    address public token;

    constructor(address _token)
        public
        ERC20Detailed("crvBUSD", "crvBUSD Token", 18)
    {
        token = _token;
    }

    function deposit(uint256 _amount) public {
        _mint(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }

    function getPricePerFullShare() public pure returns (uint256) {
        return 1e18;
    }
}

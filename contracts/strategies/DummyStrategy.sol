pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
contract DummyStrategy{
    using SafeERC20 for IERC20;

    function deposit(uint256 _amount) external {
        // IERC20(_token).transferFrom();
    }
    

}
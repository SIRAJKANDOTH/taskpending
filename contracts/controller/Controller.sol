pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IStrategy.sol";


contract Controller {
    using SafeERC20 for IERC20;
    // safe tokens to strategy address maping
    mapping(address => address) public strategies;
    

constructor () public{

}
// rewrite logic to 
function earn(address _token, uint256 _amount) public{
    address _strategy = strategies[_token];
    address _want = IStrategy(_strategy).want();
    if (_want != _token){
        // Token convertionLogic
    }
    else{
        IERC20(_token).safeTransfer(_strategy, _amount);
    }
    IStrategy(_strategy).deposit(1);
}

 function withdraw(address _token, uint256 _amount) public {
        // require(msg.sender == vaults[_token], "!vault");
        // check if requested is a vault
        IStrategy(strategies[_token]).withdraw(_amount);
    }

     function withdrawAll(address _token) public {
        // require(msg.sender == strategist || msg.sender == governance, "!strategist");
        IStrategy(strategies[_token]).withdrawAll();
    }


}
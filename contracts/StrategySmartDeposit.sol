pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract StrategySmartDeposit {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public safeAddress;
    uint256 public maxFeeLoad;
    bool private useSmartLender;

    constructor(
        address safe,
        uint256 mfl,
        address smartLender
    ) public {
        safeAddress = safe;
        maxFeeLoad = mfl;
        //create instance of smart lender as well
    }

    function getName() external pure returns (string memory) {
        return "StrategySmartDeposit";
    }

function smartDeposit (uint256 est,uint256 dv) public view returns(bool) {
    // if(this.maxFeeLoad.max(est.div(dv))){

    // }
    if((est.div(dv))>maxFeeLoad){
        return false;
    }
    else
    {
        //transfer control to smart lender
        return true;
    }
} 
    //     address smartlender,
    // uint256 maxFeeLoad,
    // bool withdrawalFeetype // 0 for fixed, 1 for declining
    // uint256 cashBalance,
    // uint256 transactionCosts
    
    // function get
}

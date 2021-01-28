pragma solidity >=0.5.0 <0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../GnosisSafe.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/ISmartLender.sol";
contract SmartLender is IStrategy,ISmartLender
{
    using SafeMath for uint256;
    using Address for address;
    address strategyManager;
    address safeAddres;
    constructor() public{
        strategyManager=msg.sender;
    }

    function getName() external pure returns (string memory) {
        return "SmartLender";
    }

// Change Existing manager
    function changeManager(address _manager) public _isAuthorised
    {
        strategyManager=_manager;
    }

// Strategry Management Privilege;
    modifier _isAuthorised{
        require(strategyManager==msg.sender,"Only Strategy Manager is allowed to access this operation");
        _;
    }


// Add money to lending pool
    function deposit(address _tokenAddress,uint256 _amount, address payable _safeAddress) public{
        GnosisSafe safe=GnosisSafe(_safeAddress);
        safe.deposit(_tokenAddress,_amount);
    }
// Withraw assets from lending pool
    function withdraw(address _tokenAddress,uint256 _shares, address payable _safeAddress) public
    {
        GnosisSafe safe=GnosisSafe(_safeAddress);
        safe.withdraw(_tokenAddress,_shares);
    }

// Request for loan
    function handleLoanRequest(address payable _requestedSafe,uint256 _amountInUSD,address _tokenAddress) public{
        GnosisSafe safe=GnosisSafe(_requestedSafe);
        address lenderSafe=safe.getLender();
        // uint256
        // tokenCountFromUSD
        uint256 lenderSafeBalanceInUsd=safe.tokenValueInUSD(safe.balanceOf(lenderSafe));
        if(lenderSafeBalanceInUsd>_amountInUSD)
        {
            //should we use transfer or mint/ burn ?
            safe.mint(safe.tokenCountFromUSD(_amountInUSD));
            safe.burn(safe.tokenCountFromUSD(_amountInUSD),lenderSafe);
        }
        else if(safe.getEstimatedReturn()>GnosisSafe(lenderSafe).getEstimatedReturn){


        }
    }

//Need to add OCB logic
    function getOCB() private returns(uint256){
        return 0;
    }

    function MintSmartLenderToken(address payable lenderAddress,uint256 tokenValueInUsd) private
    {
        GnosisSafe lenderSafe=GnosisSafe(lenderAddress);
        uint256 share=lenderSafe.tokenCountFromUSD(tokenValueInUsd);
        lenderSafe.mint(share);
    }


    function acceptLoadRequest() private{

    }

    function rejectLoanRequest() private{
        
    }


}
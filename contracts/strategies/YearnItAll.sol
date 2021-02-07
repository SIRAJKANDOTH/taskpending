pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/yearn/IVault.sol";

contract YearnItAll is ERC20,ERC20Detailed {

    constructor() public ERC20Detailed("Yearn it all","YRNITALL",18){

    }
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // yearn vault - need to confirm address

    mapping(address=>bool) private protocols;
    mapping(address=>address) private safeEnabledProtocols;
    // address public constant want = address(0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2);
    // address private crvComp=address(0x2994529C0652D127b7842094103715ec5299bBed);

   function deposit(uint256 _amount) external {
       
        IVault(safeEnabledProtocols[msg.sender]).deposit(_amount);

        // Need to add NAV logic to the vault
        _mint(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external{
        IVault(safeEnabledProtocols[msg.sender]).withdraw(_amount);
    }
    function _withdrawAllSafeBalance() private{
        IVault(safeEnabledProtocols[msg.sender]).withdraw(_getProtoColBalanceforSafe());
    }


    // Withdraw all Protocl balance to Strategy
    function withdrawAll() external returns (uint256){
        IVault(safeEnabledProtocols[msg.sender]).withdraw(IERC20(IVault(safeEnabledProtocols[msg.sender]).token()).balanceOf(msg.sender));
    }

    // Withdraw all protocol assets to safe
    function withdrawAllToSafe() external {
        _withdrawAllSafeBalance();
        _burn(msg.sender, IERC20(address(this)).balanceOf(msg.sender));
        IERC20(address(this)).transfer(msg.sender,_getProtoColBalanceforSafe());
    }

    function want() external view returns (address)
    {
       return IVault(safeEnabledProtocols[msg.sender]).token();
    }


    function _getProtoColBalanceforSafe() private view returns(uint256)
    {
        uint256 safeProtocolTokenUsd=1;
        uint256 safeShare=IERC20(address(this)).balanceOf(msg.sender);
        uint256 safeStrategyTokenUSD=1;

        // get balance from chainlink initially assumes as 1 USD
         return safeShare.mul(safeStrategyTokenUSD).div(safeProtocolTokenUsd);

    }
   }
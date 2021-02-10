pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/yearn/IVault.sol";
import "../interfaces/IExchange.sol";

contract YearnItAll is ERC20,ERC20Detailed {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
// yearn vault - need to confirm address

    address usdc=0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;
    address oneInch=0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;

    mapping(address=>bool) private protocols;
    mapping(address=>address) private safeEnabledProtocols;
    mapping(address=>address) private ChainLinkFeed;

    constructor() public ERC20Detailed("Yearn it all","YRNITALL",18){
        
        protocols[0x5b1869D9A4C187F2EAa108f3062412ecf0526b24]=true;
        // initialise yearn vaults;

    }
    

   function deposit(uint256 _amount) external {
    //    Should we use transfer/ or approve directly
        IERC20(safeEnabledProtocols[msg.sender]).approve(safeEnabledProtocols[msg.sender],_amount);
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
        uint256 SafeBalance=_getProtoColBalanceforSafe();
        _withdrawAllSafeBalance();
        _burn(msg.sender, IERC20(address(this)).balanceOf(msg.sender));
        IERC20(address(this)).transfer(msg.sender,SafeBalance);
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

    function changeProtocol(address _protocol) external{
        require(protocols[_protocol]==true, "Not an Enabled Protocols");
        require(safeEnabledProtocols[msg.sender]!=address(0), "Not a registered Safe");
        this.withdrawAll();
        address _withdrawalAsset=IVault(safeEnabledProtocols[msg.sender]).token();
        
        uint256 _balance=IERC20(_withdrawalAsset).balanceOf(address(this));
        if(_withdrawalAsset!=IVault(_protocol).token())
        {
            // Token exchange and depositi logic

            (uint256 returnAmount, uint256[] memory distribution) = IExchange(oneInch).getExpectedReturn(_withdrawalAsset, IVault(_protocol).token(), 0, 0, 0);
            IExchange(oneInch).swap(_withdrawalAsset, IVault(_protocol).token(), 0, 0, distribution, 0);
            uint256 _depositAsset=IERC20(_protocol).balanceOf(address(this));
            // Deposit balance may need to recalculate, in the case of , temporary lock from monitor. Need to discuss with Team
            safeEnabledProtocols[msg.sender]=_protocol;
            this.deposit(_depositAsset);
        }
        else{
            safeEnabledProtocols[msg.sender]=_protocol;
            this.deposit(_balance);
            
        }
    }

}
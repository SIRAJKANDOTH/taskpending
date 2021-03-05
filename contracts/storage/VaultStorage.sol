pragma solidity >=0.5.0 <0.7.0;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "../token/ERC20Detailed.sol";
import "../common/MasterCopy.sol";
import "../external/GnosisSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../token/ERC20Detailed.sol";
import "../whitelist/Whitelist.sol";
import "../interfaces/IController.sol";
import "../interfaces/IAPContract.sol";
import "../interfaces/IExchange.sol";
import "../interfaces/IStrategy.sol";
import "../utils/HexUtils.sol";
import "../utils/InstructionOracle.sol";
import "./TokenBalanceStorage.sol";
contract VaultStorage 
    is 
    MasterCopy, 
    ERC20,
    ERC20Detailed,
    ERC1155Receiver 
{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    string public vaultName;
    address public APContract;
    address public owner;
    address public vaultAPSManager;
    address public vaultStrategyManager;
    bool internal vaultSetupCompleted = false;
    bool internal vaultRegistrationCompleted = false;

    mapping(address => bool) public safeAssets;
    mapping(address=>bool) isAssetDeposited;
    address[] internal assetList;
    
    Whitelist internal whiteList;
    uint256[] internal whiteListGroups;

    address oneInch = 0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;
    address yieldsterTreasury = 0x5091aF48BEB623b3DA0A53F726db63E13Ff91df9;

    bool public emergencyExit;
    bool public emergencyBreak;

    // Token balance storage keeps track of tokens that are deposited to safe without worrying direct depoited assets affesting the NAV;
    TokenBalanceStorage tokenBalances;
    // uint public result;
    // uint public currentBlockDifference;
    // uint public currentNav;

    // Moved here for delegate purpose
    function getVaultNAV() 
        public 
        view 
        returns (uint256) 
    {
        address _strategy = IAPContract(APContract).getVaultActiveStrategy(address(this));
        uint256 nav = 0;
        for (uint256 i = 0; i < assetList.length; i++) 
        {
            if(IERC20(assetList[i]).balanceOf(address(this)) > 0)
            {
                uint256 tokenUSD = IAPContract(APContract).getUSDPrice(assetList[i]);
                nav += (IERC20(assetList[i]).balanceOf(address(this)).mul(uint256(tokenUSD)));       
            }
        }
        if(_strategy == address(0))
        {
            return nav.div(1e18);
        }
        else if(IERC20(_strategy).balanceOf(address(this)) > 0)
        {
            uint256 _strategyBalance = IERC20(_strategy).balanceOf(address(this));
            uint256 strategyTokenUsd = IStrategy(_strategy).tokenValueInUSD();
            return (nav + (_strategyBalance.mul(strategyTokenUsd)).div(1e18)).div(1e18);
        }
        return nav.div(1e18);
    }

    function getVaultNAVWithoutStrategyToken() 
        public 
        view 
        returns (uint256) 
    {
        uint256 nav = 0;
        for (uint256 i = 0; i < assetList.length; i++) 
        {
            if(IERC20(assetList[i]).balanceOf(address(this)) > 0)
            {
                uint256 tokenUSD = IAPContract(APContract).getUSDPrice(assetList[i]);
                nav += (IERC20(assetList[i]).balanceOf(address(this)).mul(uint256(tokenUSD)));       
            }
        }
        return nav.div(1e18);
    }

    function getDepositNAV(address _tokenAddress, uint256 _amount)
        view
        public
        returns (uint256)
    {
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        return (_amount.mul(uint256(tokenUSD))).div(1e18);
    }

    function tokenValueInUSD() 
        public 
        view 
        returns(uint256)
    {
        if(getVaultNAV() == 0 || totalSupply() == 0)
        {
            return 0;
        }
        else
        {
            return (getVaultNAV().mul(1e18)).div(totalSupply());
        }
    }

   
}
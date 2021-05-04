pragma solidity >=0.5.0 <0.7.0;
import "../common/MasterCopy.sol";
import "../token/ERC1155/ERC1155Receiver.sol";
import "../token/ERC20Detailed.sol";
import "../whitelist/Whitelist.sol";
import "../interfaces/IAPContract.sol";
import "../interfaces/IExchange.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IHexUtils.sol";
import "./TokenBalanceStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
contract VaultStorage 
    is 
    MasterCopy, 
    ERC20,
    ERC20Detailed,
    ERC1155Receiver 
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint8 public emergencyConditions;
    bool internal vaultSetupCompleted;
    bool internal vaultRegistrationCompleted;

    address public APContract;
    address public owner;
    address public vaultAPSManager;
    address public vaultStrategyManager;
    string public vaultName;

    uint256[] internal whiteListGroups;
    address[] internal assetList;
    mapping(address => bool) isAssetDeposited;


    // Token balance storage keeps track of tokens that are deposited to safe without worrying direct depoited assets affesting the NAV;
    TokenBalanceStorage tokenBalances;
    
    
    /// @dev Function to revert in case of delegatecall fail.
    function revertDelegate(bool delegateStatus)
        pure
        internal
    {
        if (delegateStatus == false) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    function getTokenBalance(address _tokenAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalances.getTokenBalance(_tokenAddress);
    }

    /// @dev Function to return the NAV of the Vault.
    function getVaultNAV() 
        public 
        view 
        returns (uint256) 
    {
        address[] memory strategies = IAPContract(APContract).getVaultActiveStrategy(address(this));
        uint256 nav = 0;
        for (uint256 i = 0; i < assetList.length; i++) {
            if(tokenBalances.getTokenBalance(assetList[i]) > 0) {
                uint256 tokenUSD = IAPContract(APContract).getUSDPrice(assetList[i]);
                nav += IHexUtils(IAPContract(APContract).stringUtils()).toDecimals(assetList[i], tokenBalances.getTokenBalance(assetList[i])).mul(tokenUSD);       
            }
        }
        if(strategies.length == 0) {
            return nav.div(1e18);
        } else {
            for (uint256 i = 0; i < strategies.length; i++) {
                if(IERC20(strategies[i]).balanceOf(address(this)) > 0) {
                    uint256 strategyTokenUSD = IStrategy(strategies[i]).tokenValueInUSD();
                    nav += IERC20(strategies[i]).balanceOf(address(this)).mul(strategyTokenUSD);       
                }
            }
            return nav.div(1e18);
        }
    }

    /// @dev Function to return the NAV of the Vault excluding Strategy Tokens.
    function getVaultNAVWithoutStrategyToken() 
        public 
        view 
        returns (uint256) 
    {
        uint256 nav = 0;
        for (uint256 i = 0; i < assetList.length; i++) {
            if(tokenBalances.getTokenBalance(assetList[i]) > 0) {
                uint256 tokenUSD = IAPContract(APContract).getUSDPrice(assetList[i]);
                nav += (IHexUtils(IAPContract(APContract).stringUtils()).toDecimals(assetList[i], tokenBalances.getTokenBalance(assetList[i])).mul(tokenUSD));       
            }
        }
        return nav.div(1e18);
    }

    /// @dev Function to return NAV for Deposit token and amount.
    /// @param _tokenAddress Address of the deposit Token.    
    /// @param _amount Amount of the Deposit tokens.    
    function getDepositNAV(address _tokenAddress, uint256 _amount)
        view
        internal
        returns (uint256)
    {
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        return (IHexUtils(IAPContract(APContract).stringUtils()).toDecimals(_tokenAddress, _amount).mul(tokenUSD)).div(1e18);
    }

    /// @dev Function to get the amount of Vault Tokens to be minted for the deposit NAV.
    /// @param depositNAV NAV of the Deposit Amount.
    function getMintValue(uint256 depositNAV)
        internal
        view
        returns (uint256)
    {
        return (depositNAV.mul(totalSupply())).div(getVaultNAV());
    }

    /// @dev Function to return Value of the Vault Token.
    function tokenValueInUSD() 
        public 
        view 
        returns(uint256)
    {
        if(getVaultNAV() == 0 || totalSupply() == 0) {
            return 0;
        } else {
            return (getVaultNAV().mul(1e18)).div(totalSupply());
        }
    }

}
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./common/MasterCopy.sol";
import "./external/GnosisSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./token/ERC20Detailed.sol";
import "./whitelist/Whitelist.sol";
import "./interfaces/IController.sol";
import "./interfaces/IAPContract.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/IStrategy.sol";
import "./utils/HexUtils.sol";
import "./utils/InstructionOracle.sol";

contract GnosisSafe
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

    bool private vaultSetupCompleted = false;
    bool private vaultRegistrationCompleted = false;

    mapping(address => bool) public safeAssets;
    mapping(address=>bool) isAssetDeposited;
    address[] private assetList;
    
    Whitelist private whiteList;
    string[] private whiteListGroups;

    address oneInch = 0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;

    function isWhiteListed() 
        public 
        view 
        returns (bool) 
    {
        bool memberStatus;
        if(whiteListGroups.length == 0)
        {
            memberStatus = true;
        }
        else
        {
            for (uint256 i = 0; i < whiteListGroups.length; i++) 
            {
                if (whiteList.isMember(whiteListGroups[i], msg.sender)) 
                {
                    memberStatus = true;
                    break;
                }
            }
        }
        return memberStatus;
    }

    modifier onlyWhitelisted
    {
        require(isWhiteListed(),"Not allowed to access the resources");
        _;
    }

    function setup(
        string memory _vaultName,
        string memory _tokenName,
        string memory _symbol,
        address _vaultAPSManager,
        address _vaultStrategyManager,
        address _APContract, //Need to hardcode APContract address before deploying
        string[] memory _whiteListGroups
    )
        public
    {
        require(!vaultSetupCompleted, "Vault is already setup");
        vaultSetupCompleted = true;
        vaultName = _vaultName;
        vaultAPSManager = _vaultAPSManager;
        vaultStrategyManager = _vaultStrategyManager;
        APContract = _APContract;
        owner = tx.origin;
        whiteListGroups = _whiteListGroups;
        whiteList = Whitelist(IAPContract(APContract).getwhitelistModule());
        setupToken(_tokenName, _symbol);
    }

    function registerVaultWithAPS(
        address[] memory _vaultDepositAssets,
        address[] memory _vaultWithdrawalAssets
    )
    public
    {
        require(msg.sender == owner, "Only owner can perform this operation");
        require(!vaultRegistrationCompleted, "Vault is already registered");
        vaultRegistrationCompleted = true;
        IAPContract(APContract).addVault(_vaultDepositAssets,_vaultWithdrawalAssets, vaultAPSManager,vaultStrategyManager, whiteListGroups, owner);

    }

    //Have to confirm who is authorized to call these functions
    //Function to enable a strategy and enable or disable corresponding protocol
    function setVaultStrategyAndProtocol(
        address _vaultStrategy,
        address[] memory _enabledStrategyProtocols,
        address[] memory _disabledStrategyProtocols
    )
    public
    {
        require(msg.sender == owner, "This operation can only be perfomed by Owner");
        IAPContract(APContract).setVaultStrategyAndProtocol(_vaultStrategy, _enabledStrategyProtocols, _disabledStrategyProtocols);
    }

    //Function to disable a vault strategy
    function disableVaultStrategy(address _strategyAddress)
        public
    {
        require(msg.sender == owner, "This operation can only be perfomed by Owner");
        if(getVaultActiveStrategy() == _strategyAddress)
        {
            if(IERC20(_strategyAddress).balanceOf(address(this)) > 0)
            {
                IStrategy(getVaultActiveStrategy()).withdrawAllToSafe();
            }
            IStrategy(getVaultActiveStrategy()).deRegisterSafe();
            IAPContract(APContract).deactivateVaultStrategy(_strategyAddress);
        }
        IAPContract(APContract).disableVaultStrategy(_strategyAddress);
    }

    

    //Function to set the vaults active strategy
    function setVaultActiveStrategy(address _activeVaultStrategy)
        public
    {
        require(msg.sender == owner, "This operation can only be perfomed by Owner");
        require(IAPContract(APContract)._isStrategyEnabled(address(this), _activeVaultStrategy) ,"This strategy is not enabled");
        if(getVaultActiveStrategy() != address(0))
        {
            if(IERC20(getVaultActiveStrategy()).balanceOf(address(this)) > 0)
            {
                IStrategy(getVaultActiveStrategy()).withdrawAllToSafe();
            }
            IStrategy(getVaultActiveStrategy()).deRegisterSafe();
        }

        IAPContract(APContract).setVaultActiveStrategy(_activeVaultStrategy);
        IStrategy(_activeVaultStrategy).registerSafe();        
    }

    function deactivateVaultStrategy(address _strategyAddress)
        public
    {
        require(msg.sender == owner, "This operation can only be perfomed by Owner");
        require(IAPContract(APContract)._isStrategyEnabled(address(this), _strategyAddress) ,"This strategy is not enabled");
        require(getVaultActiveStrategy() == _strategyAddress, "This strategy is not active right now");
        if(IERC20(_strategyAddress).balanceOf(address(this)) > 0)
        {
            IStrategy(getVaultActiveStrategy()).withdrawAllToSafe();
        }
        IStrategy(getVaultActiveStrategy()).deRegisterSafe();
        IAPContract(APContract).deactivateVaultStrategy(_strategyAddress);        
    }

    function getVaultActiveStrategy()
        public
        view
        returns(address)
    {
        return IAPContract(APContract).getVaultActiveStrategy(address(this));
    }

    function setStrategyActiveProtocol(address _protocol)
        public
    {
        address _strategy = IAPContract(APContract).getVaultActiveStrategy(address(this));
        require( _strategy != address(0), "No strategy is active at the moment");
        IStrategy(_strategy).setActiveProtocol(_protocol);
    }

    function getStrategyActiveProtocol()
        public
        view
        returns(address)
    {
        address _strategy = IAPContract(APContract).getVaultActiveStrategy(address(this));
        require( _strategy != address(0), "No strategy is active at the moment");
        return IStrategy(_strategy).getActiveProtocol();
    }


    //Function to get APS manager of the vault
    function getAPSManager()
        view
        public
        returns(address) 
    {
        return vaultAPSManager;
    }

    //Function to change the strategy manager of the vault
    function changeAPSManager(address _vaultAPSManager)
        public
    {
        require(IAPContract(APContract).getYieldsterDAO() == msg.sender, "This operation can only be perfomed by yieldster DAO");
        IAPContract(APContract).changeVaultAPSManager(_vaultAPSManager);
        vaultAPSManager = _vaultAPSManager;
    }

    //Function to get whitelist Manager
    function getWhitelistManager()
        public
        view
        returns(address)
    {
        return whiteList.whiteListManager();
    }

    //Function to get strategy manager of the vault
    function getStrategyManager()
        view
        public
        returns(address) 
    {
        return vaultStrategyManager;
    }

    //Function to change the strategy manager of the vault
    function changeStrategyManager(address _strategyManager)
        public
    {
        require(IAPContract(APContract).getYieldsterDAO() == msg.sender, "This operation can only be perfomed by yieldster DAO");
        IAPContract(APContract).changeVaultAPSManager(_strategyManager);
        vaultStrategyManager = _strategyManager;
    }

    //Function to find the Token to be minted for a deposit
    function getMintValue(uint256 depositNAV)
        public
        view
        returns (uint256)
    {
        return (depositNAV.mul(totalSupply())).div( getVaultNAV());
    }

    //Function to get the NAV of the vault
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
                (int256 tokenUSD, ,uint8 decimals) = IAPContract(APContract).getUSDPrice(assetList[i]);
                nav += (IERC20(assetList[i]).balanceOf(address(this)).mul(uint256(tokenUSD))).div(10 ** uint256(decimals));       
            }
        }
        if(_strategy == address(0))
        {
            return nav;
        }
        else if(IERC20(_strategy).balanceOf(address(this)) > 0)
        {
            uint256 _strategyBalance = IERC20(_strategy).balanceOf(address(this));
            uint256 strategyTokenUsd = IStrategy(_strategy).tokenValueInUSD();
            return nav + (_strategyBalance.mul(strategyTokenUsd)).div(1e18);
        }
        return nav;
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
                (int256 tokenUSD, ,uint8 decimals) = IAPContract(APContract).getUSDPrice(assetList[i]);
                nav += (IERC20(assetList[i]).balanceOf(address(this)).mul(uint256(tokenUSD))).div(10 ** uint256(decimals));       
            }
        }
        return nav;
    }

    function getDepositNAV(address _tokenAddress, uint256 _amount)
        view
        public
        returns (uint256)
    {
        (int256 tokenUSD, ,uint8 decimals) = IAPContract(APContract).getUSDPrice(_tokenAddress);
        return (_amount.mul(uint256(tokenUSD))).div(10 ** uint256(decimals));
    }

    function deposit(address _tokenAddress, uint256 _amount)
        public
        // onlyWhitelisted
    { 
        uint256 _share;
        require(IAPContract(APContract).isDepositAsset(_tokenAddress), "Not an approved deposit asset");
        IERC20 token = ERC20(_tokenAddress);

        if(totalSupply() == 0)
        {
            _share = _amount;
        }
        else
        {
            _share = getMintValue(getDepositNAV(_tokenAddress, _amount));
        }

        token.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _share);

        if(!isAssetDeposited[_tokenAddress])
        {
            isAssetDeposited[_tokenAddress] = true;
            assetList.push(_tokenAddress);
        }
    }

    function tokenCountFromUSD(uint256 amountInUsd) 
        public 
        view
        returns(uint256)
    {
        return (amountInUsd.mul(totalSupply())).div( getVaultNAV());
    }


    //Withdraw function with withdrawal asset specified
    function withdraw(address _tokenAddress, uint256 _shares)
        public
        // onlyWhitelisted
    {
        require(IAPContract(APContract).isWithdrawalAsset(_tokenAddress),"Not an approved Withdrawal asset");
        require(balanceOf(msg.sender) >= _shares,"You don't have enough shares");
        (int256 tokenUSD, ,uint8 decimals) = IAPContract(APContract).getUSDPrice(_tokenAddress);
        uint256 safeTokenVaulueInUSD = (_shares.mul(getVaultNAV())).div(totalSupply());
        uint256 tokenCount = (safeTokenVaulueInUSD.mul(10 ** uint256(decimals))).div(uint256(tokenUSD));
        
        if(tokenCount <= IERC20(_tokenAddress).balanceOf(address(this)))
        {
            _burn(msg.sender, _shares);
            IERC20(_tokenAddress).transfer(msg.sender,tokenCount);
        }
        else
        {
            uint256 need = tokenCount - IERC20(_tokenAddress).balanceOf(address(this));
            exchangeToken(_tokenAddress, need);
            _burn(msg.sender, _shares);
            IERC20(_tokenAddress).transfer(msg.sender,tokenCount);
        }
    }

    //Function to exchange a available asset to a target token
    function exchangeToken(address _targetToken, uint256 _amount)
        internal
    {
        for(uint256 i = 0; i < assetList.length; i++ )
            {
                IERC20 haveToken = IERC20(assetList[i]);
                (int256 targetTokenUSD, ,uint8 targetDecimals) = IAPContract(APContract).getUSDPrice(_targetToken);
                (int256 haveTokenUSD, ,uint8 haveDecimals) = IAPContract(APContract).getUSDPrice(assetList[i]);

                if((haveToken.balanceOf(address(this)).mul(uint256(haveTokenUSD))).div(10 ** uint256(haveDecimals)) > (_amount.mul(uint256(targetTokenUSD))).div(10 ** uint256(targetDecimals)))
                {
                    (uint256 returnAmount, uint256[] memory distribution) = 
                    IExchange(oneInch).getExpectedReturn(assetList[i], _targetToken, _amount, 0, 0);
                    uint256 adjustedAmount = _amount + (_amount - returnAmount).mul(3);

                    if( (haveToken.balanceOf(address(this)).mul(uint256(haveTokenUSD))).div(10 ** uint256(haveDecimals)) > (adjustedAmount.mul(uint256(targetTokenUSD))).div(10 ** uint256(targetDecimals)))
                    {
                        IExchange(oneInch).swap(assetList[i], _targetToken, adjustedAmount, _amount, distribution, 0);
                        break;
                    }
                    
                }                
            }
    }


    //Withdraw Function without withdrawal asset specified
    function withdraw(uint256 _shares)
        public
        // onlyWhitelisted
    {
        require(balanceOf(msg.sender) >= _shares,"You don't have enough shares");
        for(uint256 i = 0; i < assetList.length; i++ )
            {   
                IERC20 token = IERC20(assetList[i]);
                if(token.balanceOf(address(this)) > 0){
                    uint256 tokensToGive = (_shares.mul(token.balanceOf(address(this)))).div(totalSupply());
                    token.transfer(msg.sender, tokensToGive);
                }
            }
        _burn(msg.sender, _shares); 
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

    function earn(uint256 _amount) public
    {
        address _strategy = IAPContract(APContract).getVaultActiveStrategy(address(this));
        uint256 _balance = IERC20(IStrategy(_strategy).want()).balanceOf(address(this));
        if(_amount <= _balance)        
        {
            IERC20(IStrategy(_strategy).want()).approve(_strategy, _amount);
            IStrategy(_strategy).deposit(_amount);
        }
        else
        {
            exchangeToken(IStrategy(_strategy).want(),_amount);
            IERC20(IStrategy(_strategy).want()).approve(_strategy, _amount);
            IStrategy(_strategy).deposit(_amount);
        }
        
    }

    function safeCleanUp(address[] memory cleanUpList)
        public
    {
        for (uint256 i = 0; i < cleanUpList.length; i++) 
        {
            if(IAPContract(APContract)._isVaultAsset(cleanUpList[i]))
            {
                uint256 _amount = IERC20(cleanUpList[i]).balanceOf(address(this));
                if(_amount > 0)
                {
                    IERC20(cleanUpList[i]).transfer(IAPContract(APContract).getYieldsterTreasury(), _amount);
                }
            }
        }
        
    }


    // ERC1155 reciever
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
    external
    returns(bytes4)
    {
        HexUtils hexUtils = new HexUtils();
        if(id == 0)
        {
            (bool success, bytes memory result) = address(this).call(hexUtils.fromHex(data));
            if(!success){
                revert("transaction failed");
            }
        }
        else
        {
            (bool success, bytes memory result) = IAPContract(APContract).getVaultActiveStrategy(address(this)).call(hexUtils.fromHex(data));
            if(!success){
                revert("transaction failed");
            }
        }   
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
    external
    returns(bytes4)
    {
        _mint(tx.origin, 100);
        return "";
    }

}

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

    address public oneInch;

    bool public emergencyExit;
    bool public emergencyBreak;

    event EmergencyExitEnabled();
    event EmergencyBreakEnabled();
    event EmergencyBreakDisabled();


    // function isWhiteListed()
    //     public 
    //     view 
    //     returns (bool) 
    // {
    //     bool memberStatus;
    //     if(whiteListGroups.length == 0)
    //     {
    //         memberStatus = true;
    //     }
    //     else
    //     {
    //         for (uint256 i = 0; i < whiteListGroups.length; i++) 
    //         {
    //             if (whiteList.isMember(whiteListGroups[i], msg.sender)) 
    //             {
    //                 memberStatus = true;
    //                 break;
    //             }
    //         }
    //     }
    //     return memberStatus;
    // }

    // modifier onlyWhitelisted
    // {
    //     require(isWhiteListed(),"Not allowed to access the resources");
    //     _;
    // }

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
        APContract = _APContract; //hardcode APContract address here before deploy to mainnet
        owner = tx.origin;
        whiteListGroups = _whiteListGroups;
        whiteList = Whitelist(IAPContract(APContract).getwhitelistModule());
        oneInch = 0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;
        setupToken(_tokenName, _symbol);
    }

    function registerVaultWithAPS(
        address[] memory _vaultDepositAssets,
        address[] memory _vaultWithdrawalAssets
    )
    onlyNormalMode
    public
    {
        require(msg.sender == owner, "Only owner can perform this operation");
        require(!vaultRegistrationCompleted, "Vault is already registered");
        vaultRegistrationCompleted = true;
        IAPContract(APContract).addVault(_vaultDepositAssets,_vaultWithdrawalAssets, vaultAPSManager,vaultStrategyManager, whiteListGroups, owner);
    }

    // Have to confirm who is authorized to call these functions
    // Function to enable a strategy and enable or disable corresponding protocol
    function setVaultStrategyAndProtocol(
        address _vaultStrategy,
        address[] memory _enabledStrategyProtocols,
        address[] memory _disabledStrategyProtocols
    )
    onlyNormalMode
    public
    {
        require(msg.sender == owner, "This operation can only be perfomed by Owner");
        IAPContract(APContract).setVaultStrategyAndProtocol(_vaultStrategy, _enabledStrategyProtocols, _disabledStrategyProtocols);
    }

    function disableVaultStrategy(address _strategyAddress)
        onlyNormalMode
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

    
    function setVaultActiveStrategy(address _activeVaultStrategy)
        onlyNormalMode
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
        onlyNormalMode
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
        onlyNormalMode
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

    //Emergency Functions 
    function enableEmergencyBreak()
        public
    {
        require(msg.sender == IAPContract(APContract).getYieldsterGOD(), "Only yieldster GOD can perform this operation");
        emergencyBreak = true;
        emit EmergencyBreakEnabled();
    }

    function disableEmergencyBreak()
        public
    {
        require(msg.sender == IAPContract(APContract).getYieldsterGOD(), "Only yieldster GOD can perform this operation");
        emergencyBreak = false;
        emit EmergencyBreakDisabled();
    }

    function enableEmergencyExit()
        public
    {
        require(msg.sender == IAPContract(APContract).getYieldsterGOD(), "Only yieldster GOD can perform this operation");
        emergencyExit = true;
        address vaultActiveStrategy = getVaultActiveStrategy();
        if(vaultActiveStrategy != address(0))
        {
            IStrategy(getVaultActiveStrategy()).withdrawAllToSafe();
            IStrategy(getVaultActiveStrategy()).deRegisterSafe();
        }
        for(uint256 i = 0; i < assetList.length; i++ )
        {   
            IERC20 token = IERC20(assetList[i]);
            uint256 tokenBalance = token.balanceOf(address(this));
            if(tokenBalance > 0)
            {
                token.transfer(IAPContract(APContract).getEmergencyVault(), tokenBalance);
            }
        }
        emit EmergencyExitEnabled();
    }

    modifier onlyNormalMode
    {
        if(emergencyBreak)
        {
            require(msg.sender == IAPContract(APContract).getYieldsterGOD(), "Only yieldster GOD can perform this operation");
        }
        else if(emergencyExit)
        {
            revert("This safe is no longer active");
        }
        _;
    }

    //Function to change the strategy manager of the vault
    function changeAPSManager(address _vaultAPSManager)
        onlyNormalMode
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


    //Function to change the strategy manager of the vault
    function changeStrategyManager(address _strategyManager)
        onlyNormalMode
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

    function deposit(address _tokenAddress, uint256 _amount)
        onlyNormalMode
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

    //Withdraw function with withdrawal asset specified
    function withdraw(address _tokenAddress, uint256 _shares)
        onlyNormalMode
        public
        // onlyWhitelisted
    {
        require(IAPContract(APContract).isWithdrawalAsset(_tokenAddress),"Not an approved Withdrawal asset");
        require(balanceOf(msg.sender) >= _shares,"You don't have enough shares");
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        uint256 safeTokenVaulueInUSD = (_shares.mul(getVaultNAV())).div(totalSupply());
        uint256 tokenCount = (safeTokenVaulueInUSD.mul(1e18)).div(uint256(tokenUSD));
        
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
                uint256 targetTokenUSD = IAPContract(APContract).getUSDPrice(_targetToken);
                uint256 haveTokenUSD = IAPContract(APContract).getUSDPrice(assetList[i]);

                if((haveToken.balanceOf(address(this)).mul(uint256(haveTokenUSD))).div(1e18) > (_amount.mul(uint256(targetTokenUSD))).div(1e18))
                {
                    (uint256 returnAmount, uint256[] memory distribution) = 
                    IExchange(oneInch).getExpectedReturn(assetList[i], _targetToken, _amount, 0, 0);
                    uint256 adjustedAmount = _amount + (_amount - returnAmount).mul(3);

                    if( (haveToken.balanceOf(address(this)).mul(uint256(haveTokenUSD))).div(1e18) > (adjustedAmount.mul(uint256(targetTokenUSD))).div(1e18))
                    {
                        IExchange(oneInch).swap(assetList[i], _targetToken, adjustedAmount, _amount, distribution, 0);
                        break;
                    }
                    
                }                
            }
    }

    //Withdraw Function without withdrawal asset specified
    function withdraw(uint256 _shares)
        onlyNormalMode
        public
        // onlyWhitelisted
    {
        require(balanceOf(msg.sender) >= _shares,"You don't have enough shares");
        uint256 safeTotalSupply = totalSupply();
        _burn(msg.sender, _shares); 

        
        if(getVaultActiveStrategy() != address(0))
        {
            uint256 safeStrategyBalance = IERC20(getVaultActiveStrategy()).balanceOf(address(this));
            if(safeStrategyBalance > 0)
            {
                uint256 strategyShares = (_shares.mul(safeStrategyBalance)).div(safeTotalSupply); 
                IERC20(getVaultActiveStrategy()).transfer(msg.sender,strategyShares);
            }
        }

        for(uint256 i = 0; i < assetList.length; i++ )
        {   
            IERC20 token = IERC20(assetList[i]);
            if(token.balanceOf(address(this)) > 0){
                uint256 tokensToGive = (_shares.mul(token.balanceOf(address(this)))).div(safeTotalSupply);
                token.transfer(msg.sender, tokensToGive);
            }
        }
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

    function earn(uint256 _amount) 
        onlyNormalMode
        public
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
        onlyNormalMode
        public
    {
        for (uint256 i = 0; i < cleanUpList.length; i++) 
        {
            if(! (IAPContract(APContract)._isVaultAsset(cleanUpList[i])))
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
        else if(id == 1)
        {
            (bool success, bytes memory result) = IAPContract(APContract).getVaultActiveStrategy(address(this)).call(hexUtils.fromHex(data));
            if(!success){
                revert("transaction failed");
            }
        }   
        else
        {
            address smartStrategy = IAPContract(APContract).getStrategyInstructionId(id);
            (bool success, bytes memory result) = address(smartStrategy).delegatecall(hexUtils.fromHex(data));
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

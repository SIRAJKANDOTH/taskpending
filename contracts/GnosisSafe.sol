// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./common/MasterCopy.sol";
import "./external/GnosisSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./token/ERC20Detailed.sol";
import "./whitelist/Whitelist.sol";
import "./interfaces/IController.sol";
import "./interfaces/IAPContract.sol";
import "./interfaces/IExchange.sol";

/// @title Gnosis Safe - A multisignature wallet with support for confirmations using signed messages based on ERC191.
/// @author Stefan George - <stefan@gnosis.io>
/// @author Richard Meissner - <richard@gnosis.io>
/// @author Ricardo Guilherme Schmidt - (Status Research & Development GmbH) - Gas Token Payment
contract GnosisSafe
    is 
    MasterCopy, 
    ERC20,
    ERC20Detailed {

    // using GnosisSafeMath for uint256;
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
    address[] private assetList;
    mapping(address=>bool) isAssetDeposited;

    mapping(address => bool) public safeAssets;
    
    string[] private whiteListGroups;
    Whitelist private whiteList;


    function isWhiteListed() public view returns (bool) {
        bool memberStatus;
        for (uint256 i = 0; i < whiteListGroups.length; i++) {
            if (whiteList.isMember(whiteListGroups[i], msg.sender)) {
                memberStatus = true;
                break;
            }
        }
        return memberStatus;
    }

    modifier onlyWhitelisted{
        require(isWhiteListed(),"Not allowed to access the resources");
        _;
    }

    // /// @dev Setup function sets initial storage of contract.
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
        address[] memory _vaultWithdrawalAssets,
        address[] memory _vaultEnabledStrategies
    )
    public
    {
        require(msg.sender == owner, "Only owner can perform this operation");
        require(!vaultRegistrationCompleted, "Vault is already registered");
        vaultRegistrationCompleted = true;
        IAPContract(APContract).addVault(_vaultDepositAssets,_vaultWithdrawalAssets, _vaultEnabledStrategies, vaultAPSManager,vaultStrategyManager, whiteListGroups, owner);

    }

    //Function to enable a strategy and the corresponding protocol
        function setVaultStrategyAndProtocol(
        address _vaultStrategy,
        address[] memory _strategyProtocols
    )
    public
    {
        require(msg.sender == vaultAPSManager, "This operation can only be perfomed by APS Manager");
        IAPContract(APContract).setVaultStrategyAndProtocol(_vaultStrategy, _strategyProtocols);
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


    //Using OpenZeppelin function
    //TODO: NAV Methods
    function getMintValue(uint256 vaultNAV, uint256 depositNAV)
        private
        view
        returns (uint256)
    {
        return depositNAV.div(vaultNAV.div(totalSupply()));
    }


    function getVaultNAV() private view returns (uint256) {
        uint256 nav = 0;
        for (uint256 i = 0; i < assetList.length; i++) {
                (int256 tokenUSD, ) =
                    IAPContract(APContract
                    ).getUSDPrice(assetList[i]);
                nav += (IERC20(assetList[i]).balanceOf(address(this)) * uint256(tokenUSD));       
    }
     return nav;
    }
    function getDepositNav(address _tokenAddress, uint256 _amount)
        view
        private
        returns (uint256)
    {
        (int256 tokenUSD, ) = IAPContract(APContract).getUSDPrice(_tokenAddress);
        return _amount.mul(uint256(tokenUSD));
    }

    function deposit(address _tokenAddress, uint256 _amount)
        public
        onlyWhitelisted
    { 
        uint256 _share;
        require(IAPContract(APContract).isDepositAsset(_tokenAddress), "Not a approved deposit assets!");
        IERC20 token = ERC20(_tokenAddress);
        token.transferFrom(msg.sender, address(this), _amount);

        if(totalSupply() == 0){
            _share = _amount;
        }
        else{
            _share = getMintValue(getVaultNAV(), getDepositNav(_tokenAddress, _amount));
        }
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
        return amountInUsd.div(getVaultNAV().div(totalSupply()));
    }

    function mint(uint256 _amount) external{
        _mint(msg.sender, _amount);
    }
    function burn(uint256 _amount,address _lender) external{
        _burn(_lender, _amount);
    }


    function withdraw(address _tokenAddress, uint256 _shares)
        public
        onlyWhitelisted
    {
        require(IAPContract(APContract).isWithdrawalAsset(_tokenAddress),"Not a approved Withdrawal asset");
        require(balanceOf(msg.sender) >= _shares,"You don't have enough shares");
         (int256 tokenUSD, ) =
            IAPContract(APContract
            ).getUSDPrice(_tokenAddress);
            uint256 safeValueInUSD = tokenValueInUSD(_shares);
            uint256 tokenCount = safeValueInUSD.div(uint256(tokenUSD));
            if(tokenCount > IERC20(_tokenAddress).balanceOf(address(this)))
            {
                _burn(msg.sender, _shares);
                IERC20(_tokenAddress).transfer(msg.sender,tokenCount);
            }
            // Exchange token
            else{
                uint256 need = tokenCount - IERC20(_tokenAddress).balanceOf(address(this));
                for(uint256 i = 0; i < assetList.length; i++ ){
                    IERC20 haveToken = IERC20(assetList[i]);
                    uint256 haveTokenCount = haveToken.balanceOf(address(this));
                    (int256 haveTokenUSD, ) = IAPContract(APContract).getUSDPrice(assetList[i]);
                    if(haveTokenCount.mul(uint256(haveTokenUSD)) > need.mul(uint256(tokenUSD)))
                    {
                        address converter = IAPContract(APContract).getConverter(assetList[i], _tokenAddress);
                        if(converter != address(0))
                        {
                            (
                                uint256 returnAmount, uint256[] memory distribution
                            )= IExchange(converter).getExpectedReturn(haveToken,IERC20(_tokenAddress),need,0,0);
                            if( haveTokenCount.mul(uint256(haveTokenUSD)) > (need+(need-returnAmount).mul(3)).mul(uint256(tokenUSD)))
                            {
                                IExchange(converter).swap(IERC20(assetList[i]),IERC20(_tokenAddress),need+(need-returnAmount).mul(3),need,distribution,0);
                                _burn(msg.sender, _shares);
                                IERC20(_tokenAddress).transfer(msg.sender,tokenCount);
                                break;
                            }
                        
                        }

                    }
                    
                }

            }
    
    }


    function tokenValueInUSD(uint256 tokenCount) public view returns(uint256)
    {
        return getVaultNAV().div(totalSupply()).mul(tokenCount);
    }

}

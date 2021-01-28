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

     function earn() public {
        uint256 _bal = totalSupply();
        // transfer(controller, _bal);
        // IController(controller).earn(address(token), _bal);
    }

    function getVaultNAV() private returns (uint256) {
        uint256 nav = 0;
        for (uint256 i = 0; i < assetList.length; i++) {
                (int256 tokenUSD, uint256 timestamp) =
                    IAPContract(APContract
                    ).getUSDPrice(assetList[i]);
                nav += (IERC20(assetList[i]).balanceOf(this) * uint256(tokenUSD));
            
        // }
        return nav;
    }
    }
    function getDepositNav(address _tokenAddress, uint256 _amount)
        private
        returns (uint256)
    {
        (int256 tokenUSD, uint256 timestamp) =
            IAPContract(APContract).getUSDPrice(_tokenAddress);
        return _amount.mul(uint256(tokenUSD));
    }

    function deposit(address _tokenAddress, uint256 _amount)
        public
        onlyWhitelisted
    { 
        require(IAPContract(APContract).vaults(address(this)).vaultDepositAssets(_tokenAddress),"Not a approved deposit assets!");
        IERC20 token = ERC20(_tokenAddress);
        token.transferFrom(msg.sender, address(this), _amount);
        uint256 _share;
        if(totalSupply()==0){
            _share=_amount;
        }
        else{
            _share = getMintValue(getVaultNAV(), getDepositNav(_tokenAddress, _amount));
        }
        _mint(msg.sender, _share);
        if(!isAssetDeposited[_tokenAddress])
        {
            isAssetDeposited[_tokenAddress]=true;
            assetList.push(_tokenAddress);
        }
    }


    function tokenValueInUSD(uint256 tokenCount) public pure returns(uint256)
    {
        return tokenCount.mul(1);
    }
    function tokenCountFromUSD(uint256 amountInUsd) public pure returns(uint256)
    {
        return amountInUsd.div(1);
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
        // uint256 r = (vaultBalance().mul(_shares)).div(totalSupply());
         (int256 tokenUSD, uint256 timestamp) =
            IAPContract(APContract
            ).getUSDPrice(_tokenAddress);
        // uint256 tokensBurned = vaultBalance(_tokenAddress).mul(_shares).div(totalSupply());
        uint256 liquidationCosts=0;
        // uint256 navw = ((getVaultNAV().div(totalSupply())).mul(tokensBurned)) - liquidationCosts;
        IERC20 token = ERC20(_tokenAddress);
        _burn(msg.sender, _shares);
        // token.transfer(msg.sender, navw);
    }

        // Check balance
        // uint256 b = token.balanceOf(address(this));
        // if (b < r) {
        //     uint256 _withdraw = r.sub(b);
        //     IController(controller).withdraw(address(token), _withdraw);
        //     uint256 _after = token.balanceOf(address(this));
        //     uint256 _diff = _after.sub(b);
        //     if (_diff < _withdraw) {
        //         r = b.add(_diff);
        //     }
        // }

        // token.transfer(msg.sender, _shares);
    function getEstimatedReturn() public view returns(uint256){
        return 1;

    }

}

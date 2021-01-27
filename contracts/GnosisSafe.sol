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

    string public safeName = "Gnosis Safe";
    string public version = "1.2.0";

    address public APContract;
    address public owner;
    address public vaultAPSManager;
    address public vaultStrategyManager;

    bool private vaultSetupCompleted = false;

    mapping(address => bool) public safeAssets;
    
    string[] private whiteListGroups;
    Whitelist private whiteList;


    function isWhiteListed() public view returns(bool){
        bool memberStatus;
        for(uint256 i=0;i<whiteListGroups.length;i++)
        {

            if(whiteList.isMember(whiteListGroups[i],msg.sender))
            {
                memberStatus=true;
                break;
            }
        }
        return memberStatus;

    }

    modifier onlyWhitelisted{
        require(isWhiteListed(),"Not allowed to access the resources");
        _;
    }

    /// @dev Setup function sets initial storage of contract.
    function setup(
        // string calldata _safeName,  //commented out to deal with stack too deep error
        string calldata _tokenName,
        string calldata _symbol,
        address _vaultAPSManager,
        address _vaultStrategyManager,
        address _APContract, //Need to hardcode APContract address before deploying
        address[] calldata _vaultAssets,
        string[] calldata _whitelistGroup
    )
        external
    {
        require(!vaultSetupCompleted, "Safe is already setup");

        vaultSetupCompleted = true;
        // safeName = _safeName;    //to be uncommented when deploying 
        vaultAPSManager = _vaultAPSManager;
        vaultStrategyManager = _vaultStrategyManager;
        APContract = _APContract;
        owner = msg.sender;

        whiteList = Whitelist(IAPContract(APContract).getwhitelistModule());

        setupToken(_tokenName, _symbol);
        IAPContract(APContract).addVault(_vaultAssets, _vaultAPSManager,_vaultStrategyManager, _whitelistGroup);

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
    function deposit(uint256 _amount) public onlyWhitelisted{
        // uint256 _pool = vaultBalance();
        // uint256 _before = token.balanceOf(address(this));
        // token.transferFrom(msg.sender, address(this), _amount);
        // uint256 _after = token.balanceOf(address(this));
        // _amount = _after.sub(_before); // Additional check for deflationary tokens
        // uint256 shares = 0;
        // if (token.totalSupply() == 0) {
        //     shares = _amount;
        // } else {
        //     shares = (_amount.mul(token.totalSupply())).div(_pool);
        // }
        _mint(msg.sender, _amount);
    }

    function withdraw(uint256 _shares) public onlyWhitelisted{
        // uint256 r = (vaultBalance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

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
    }

}

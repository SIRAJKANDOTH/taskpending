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

    address public APSController;
    address public owner;
    address public manager;
    bool private safeSetupCompleted = false;
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
        // string calldata _safeName,
        string calldata _tokenName,
        string calldata _symbol,
        address _manager,
        address _APSController, 
        address[] calldata _vaultAssets,
        address[] calldata _vaultProtocols,
        string[] calldata _whitelistGroup
    )
        external
    {
        require(!safeSetupCompleted, "Safe is already setup");

        safeSetupCompleted = true;
        // safeName = _safeName;
        manager = _manager;
        APSController = _APSController;
        owner = msg.sender;

        setupToken(_tokenName, _symbol);

        IAPContract(APSController).addVault(_vaultAssets, _vaultProtocols, manager, _whitelistGroup);

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

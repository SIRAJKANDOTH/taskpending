pragma solidity >=0.5.0 <0.7.0;
import "./base/FallbackManager.sol";
import "./common/MasterCopy.sol";
import "./external/GnosisSafeMath.sol";
import "./yrToken.sol";
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
    is MasterCopy, 
    FallbackManager, 
    ERC20,
    ERC20Detailed {

    // using GnosisSafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    string public safeName = "Gnosis Safe";
    string public version = "1.2.0";

    IERC20 private token;
    address public controller;
    address public owner;
    address public manager;
    mapping(address => bool) public safeAssets;
    string[] private whiteListGroups;
    Whitelist private whiteList;

    //keccak256(
    //    "EIP712Domain(address verifyingContract)"
    //);
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

    bytes32 public domainSeparator;


    function vaultBalance() public view returns (uint256) {
        return token.balanceOf(address(this)).add(IController(controller).balanceOf(address(token)));
    }

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
        require(isWhiteListed(),"Note allowed to access the resources");
        _;
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param fallbackHandler Handler for fallback calls to this contract

    function setup(
        string calldata _safeName,
        string calldata _tokenName,
        string calldata _symbol,
        address _manager,
        address _controller, 
        address[] calldata _safeAssets,
        address _whitelisted,
        address fallbackHandler

    )
        external
    {
        require(domainSeparator == 0, "Domain Separator already set!");
        domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, this));
        // setupOwners(_owners, _threshold);
        if (fallbackHandler != address(0)) internalSetFallbackHandler(fallbackHandler);

        safeName = _safeName;
        manager = _manager;
        controller = _controller;
        owner = msg.sender;

        setupToken(_tokenName, _symbol);

        //Adding assets to the safe
         for (uint256 i = 0; i < _safeAssets.length; i++) {
            address asset = _safeAssets[i];
            require(asset != address(0), "Invalid asset provided");
            require(IAPContract(controller).isAssetPresent(asset), "Asset not supported by Yieldster");
            safeAssets[asset] = true;
        }
        //Setting up whitelist
        whiteList=Whitelist(_whitelisted);
        whiteListGroups=["GROUPA","GROUPB"];
    }
    

    //Using OpenZeppelin function
    function deposit(uint256 _amount) public onlyWhitelisted{
        // uint256 _pool = vaultBalance();
        // uint256 _before = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), _amount);
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

        token.transfer(msg.sender, _shares);
    }

}

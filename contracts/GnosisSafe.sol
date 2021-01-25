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
    is MasterCopy, 
    ERC20,
    ERC20Detailed {

    // using GnosisSafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    string public safeName = "Gnosis Safe";
    string public version = "1.2.0";

    address public apsContract
    ;
    address public owner;
    address public manager;
    bool private safeSetupCompleted = false;
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

    /// @dev Setup function sets initial storage of contract.
    function setup(
        // string calldata _safeName,
        string calldata _tokenName,
        string calldata _symbol,
        // address _manager,
        address _apsContract
        , 
        address[] calldata _vaultAssets,
        address[] calldata _vaultProtocols,
        string[] calldata _whitelistGroup
    )
        external
    {
        require(!safeSetupCompleted, "Safe is already setup");

        safeSetupCompleted = true;
        // safeName = _safeName;
        // manager = _manager;
        apsContract
         = _apsContract
        ;
        owner = msg.sender;
        setupToken(_tokenName, _symbol);

        IAPContract(apsContract
        ).addVault(_vaultAssets, _vaultProtocols, msg.sender, _whitelistGroup);

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
        // mapping(address=>bool) depositedTokens;
        uint256 nav = 0;
        for (uint256 i = 0; i < tokensList.length; i++) {
            if (depositedTokens[tokensList[i]]) {
                (int256 tokenUSD, uint256 timestamp) =
                    IAPContract(apsContract
                    ).getUSDPrice(tokensList[i]);
                nav += (vaultBalance(tokensList[i]) * uint256(tokenUSD));
                // .div(
                //     totalSupply()
                // );
            }
        }
        return nav;
    }

    function getDepositNav(address _tokenAddress, uint256 _amount)
        private
        returns (uint256)
    {
        (int256 tokenUSD, uint256 timestamp) =
            IAPContract(apsContract
            ).getUSDPrice(_tokenAddress);
        return _amount.mul(uint256(tokenUSD));
    }

    function deposit(address _tokenAddress, uint256 _amount)
        public
        onlyWhitelisted
    {
        IERC20 token = ERC20(_tokenAddress);
        token.transferFrom(msg.sender, address(this), _amount);

        if(isSmartDeposit){
            //hook into smart deposit
            //send token.balanceOf(address(this)) to smart deposit
        }
        else {
            uint256 _share = getMintValue(getVaultNAV(), getDepositNav(_tokenAddress, _amount));
            _mint(msg.sender, _share);
        }

    }
 // SET lender
    function setLender(address _lender) public
    {
        smartLender=_lender;
    }

    // GET lender

    function getLender() public view returns(address)
    {
        return smartLender;
    }

// Get USD value of given number of safeTokens
// Todo: add logic to get usd of single token
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
            IAPContract(apsContract
            ).getUSDPrice(_tokenAddress);
        uint256 tokensBurned = vaultBalance(_tokenAddress).mul(_shares).div(totalSupply());
        uint256 liquidationCosts=0;
        uint256 navw = ((getVaultNAV().div(totalSupply())).mul(tokensBurned)) - liquidationCosts;
        IERC20 token = ERC20(_tokenAddress);
        _burn(msg.sender, _shares);
        token.transfer(msg.sender, navw);
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
    function getEstimatedReturn() public view{
        return 1;

    }

}

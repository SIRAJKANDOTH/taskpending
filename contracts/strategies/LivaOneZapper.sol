pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAPContract.sol";
import "../interfaces/yearn/IVault.sol";
import "../interfaces/zapper/IZapper.sol";
import "../interfaces/IExchange.sol";

contract LivaOneZapper 
    is 
    ERC20,
    ERC20Detailed 
{
// ToDO: change protocol, withdraw to strategy
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
// yearn vault - need to confirm address

    address curveZapper = 0x462991D18666c578F787e9eC0A74Cd18D2971E5F;
    address zapOutZontract= 0xB0880df8420974ef1b040111e5e0e95f05F8fee1;
    address APContract;
    address owner;
    //  1% slipage
    uint256 slipage=100;

    address[] public protocolList;
    mapping(address => bool) private protocols;
    mapping(address => address) private safeActiveProtocol;
    mapping(address => bool) isRegistered;

    modifier onlyRegisteredSafe
    {
        require( isRegistered[msg.sender], "Not a registered Safe");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Only permitted to owner");
          _;
    }


    function addProtocol(address _protocolAddress) 
        public 
        onlyOwner
    {
        require(_protocolAddress != address(0), "Zero address");
        protocolList.push(_protocolAddress);
    }


    constructor(address _APContract, address[] memory _protocols) 
    public 
    ERC20Detailed("LVAONE", "LIVA ONE", 18)
    {
        APContract = _APContract;
        for (uint256 i = 0; i < _protocols.length; i++) {
            protocols[_protocols[i]] = true;
            protocolList.push(_protocols[i]);
        }
        owner = msg.sender;
    }

    function setActiveProtocol(address _protocol)
        onlyRegisteredSafe
        public
    {
        require(protocols[_protocol], "This protocol is not present in the strategy");
        require(IAPContract(APContract)._isStrategyProtocolEnabled(msg.sender, address(this), _protocol), "This protocol is not enabled for this safe");
        safeActiveProtocol[msg.sender] = _protocol;
    }

    function setSlipage(uint256 _slipage) 
        public 
        onlyOwner
    {
        require(_slipage < 10000, "! percentage");
        slipage = _slipage;
    }

    function setAPContract(address _APContract) 
        public 
        onlyOwner
    {
        APContract = _APContract;
    }

    function getActiveProtocol(address _safeAddress)
        public
        view 
        returns(address)
    {
        require( isRegistered[_safeAddress], "Not a registered Safe");
        return safeActiveProtocol[_safeAddress];
    }

    function registerSafe()
        public
    {
        isRegistered[msg.sender] = true;
    }

    function deRegisterSafe()
        onlyRegisteredSafe
        public
    {
        safeActiveProtocol[msg.sender] = address(0);
        isRegistered[msg.sender] = false;
    }

    function deposit(address _depositAsset,uint256 _amount) 
        onlyRegisteredSafe
        public 
    {
        uint256 _shares;
        address _yVault = safeActiveProtocol[msg.sender];
        IERC20(_depositAsset).transferFrom(msg.sender, address(this), _amount);
        uint256 yvtokenPriceInUSD = IAPContract(APContract).getUSDPrice(_yVault);
        uint256 strategyshareInUSD = _amount.mul(IAPContract(APContract).getUSDPrice(_depositAsset)).div(1e18);
        uint256 equivalentyvTokenCount = strategyshareInUSD.mul(1e18).div(yvtokenPriceInUSD);
        uint256 minReturnTokens = equivalentyvTokenCount - equivalentyvTokenCount.mul(slipage).div(10000);
        IERC20(_depositAsset).approve(curveZapper,  _amount);
        bytes memory swapData;
        IZapper(curveZapper).ZapInCurveVault(_depositAsset, _amount,_depositAsset,_yVault,minReturnTokens,address(0),swapData,address(0));

        if(totalSupply() == 0) _shares = _amount;
        else _shares = getMintValue(getDepositNAV(_depositAsset, _amount));

        if(_shares > 0) _mint(msg.sender, _shares);
    }

    //Function to find the Token to be minted for a deposit
    function getMintValue(uint256 depositNAV)
        public
        view
        returns (uint256)
    {
        return (depositNAV.mul(totalSupply())).div(getStrategyNAV());
    }

     //Function to get the NAV of the strategy
    function getStrategyNAV() 
        public 
        view 
        returns (uint256) 
    {
        uint256 strategyNAV = 0;
        for (uint256 i = 0; i < protocolList.length; i++) {
            if(IERC20(protocolList[i]).balanceOf(address(this)) > 0) {
                uint256 tokenUSD = IAPContract(APContract).getUSDPrice(protocolList[i]);
                strategyNAV += (IERC20(protocolList[i]).balanceOf(address(this)).mul(uint256(tokenUSD)));       
            }
        }
        return strategyNAV.div(1e18);
    }

    function getDepositNAV(address _tokenAddress, uint256 _amount)
        view
        public
        returns (uint256)
    {
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        return (_amount.mul(uint256(tokenUSD))).div(1e18);
    }

    function tokenValueInUSD() public view returns(uint256)
    {
        if(getStrategyNAV() == 0 || totalSupply() == 0) {
            return 0;
        } else {
            return (getStrategyNAV().mul(1e18)).div(totalSupply());
        }
    }


    function withdraw(uint256 _shares,address _withrawalAsset) 
        onlyRegisteredSafe
        public
        returns(address,uint256)
    {
        require(balanceOf(msg.sender) >= _shares,"Not enough shares");
        uint256 strategyTokenValueInUSD = (_shares.mul(getStrategyNAV())).div(totalSupply());
        uint256 vaultTokenPriceInUSD = IAPContract(APContract).getUSDPrice(safeActiveProtocol[msg.sender]);
        uint256 vaultTokensToRemoved = strategyTokenValueInUSD.mul(1e18).div(vaultTokenPriceInUSD);
        uint256 minTokensCount = vaultTokensToRemoved - vaultTokensToRemoved.mul(slipage).div(10000);
        _burn(msg.sender, _shares);
        if(_withrawalAsset == address(0)) {
            IERC20(safeActiveProtocol[msg.sender]).transfer(msg.sender,vaultTokensToRemoved);
            return (safeActiveProtocol[msg.sender],vaultTokensToRemoved);   
        } else {
            uint256 returnedTokens = IZapper(zapOutZontract).ZapOut(msg.sender,_withrawalAsset,safeActiveProtocol[msg.sender],2,vaultTokensToRemoved,minTokensCount);
            return (_withrawalAsset, returnedTokens);   
        }
    }


    function _changeProtocol(address _protocol) private
    {
        uint256 _shares = _getProtocolBalanceForSafe();
        uint256 strategyTokenValueInUSD = (_shares.mul(getStrategyNAV())).div(totalSupply());
        uint256 tokensToBeChanged = strategyTokenValueInUSD.mul(1e18).div(IAPContract(APContract).getUSDPrice(safeActiveProtocol[msg.sender]));
        uint256 mintokens = tokensToBeChanged-tokensToBeChanged.mul(slipage).div(10000);
        IERC20(safeActiveProtocol[msg.sender]).approve(curveZapper, tokensToBeChanged);
        bytes memory swapData;
        IZapper(curveZapper).ZapInCurveVault(safeActiveProtocol[msg.sender], tokensToBeChanged, safeActiveProtocol[msg.sender], _protocol, mintokens, address(0), swapData, address(0));
        safeActiveProtocol[msg.sender] = _protocol;
    }

    // Withdraw all protocol assets to safe
    function withdrawAllToSafe(address _withdrawalToken) 
        public 
        onlyRegisteredSafe
        returns(address,uint256)
    {
        uint256 SafeProtocolBalance = _getProtocolBalanceForSafe();
        return withdraw(SafeProtocolBalance, _withdrawalToken);
    }

    function want() external view returns (address)
    {
       return IVault(safeActiveProtocol[msg.sender]).token();
    }


    function _getProtocolBalanceForSafe()
        onlyRegisteredSafe 
        private 
        view 
        returns(uint256)
    {
        uint256 _shares = balanceOf(msg.sender);
        address _protocolAddress = safeActiveProtocol[msg.sender];
        uint256 strategyTokenValueInUSD = (_shares.mul(getStrategyNAV())).div(totalSupply());
        uint256 protocolTokenUSD = IAPContract(APContract).getUSDPrice(_protocolAddress);
        uint256 _protocolShares = (strategyTokenValueInUSD.mul(1e18)).div(uint256(protocolTokenUSD));
        return _protocolShares;
    }

    function changeProtocol(address _protocol) 
        onlyRegisteredSafe
        external
    {
        require(protocols[_protocol], "Not an Enabled Protocols");
        require(IAPContract(APContract)._isStrategyProtocolEnabled(msg.sender, address(this), _protocol), "This protocol is not enabled for this safe");
       _changeProtocol(_protocol);
    }

}
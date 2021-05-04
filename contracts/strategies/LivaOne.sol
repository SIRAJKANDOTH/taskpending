pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAPContract.sol";
import "../interfaces/yearn/IVault.sol";
import "../interfaces/IExchange.sol";

contract LivaOne 
    is 
    ERC20,
    ERC20Detailed 
{

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // string public test="test";
    
// yearn vault - need to confirm address

    address usdc = 0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;
    address oneInch = 0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;
    address APContract;

    address[] public protocolList;
    mapping(address => bool) private protocols;
    mapping(address => address) private safeActiveProtocol;
    mapping(address => bool) isRegistered;

    modifier onlyRegisteredSafe
    {
        require( isRegistered[msg.sender], "Not a registered Safe");
        _;
    }


    constructor(address _APContract, address[] memory _protocols) 
    public 
    ERC20Detailed("ylLIVA", "Liva One", 18)
    {
        APContract = _APContract;
        for (uint256 i = 0; i < _protocols.length; i++) 
        {
            protocols[_protocols[i]] = true;
            protocolList.push(_protocols[i]);
        }
    }

    function setActiveProtocol(address _protocol)
        onlyRegisteredSafe
        public
    {
        require(protocols[_protocol], "This protocol is not present in the strategy");
        require(IAPContract(APContract)._isStrategyProtocolEnabled(msg.sender, address(this), _protocol), "This protocol is not enabled for this safe");
        safeActiveProtocol[msg.sender] = _protocol;
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

    function deposit(uint256 _amount) 
        onlyRegisteredSafe
        public 
    {
        uint256 _shares;
        address _tokenAddress = IVault(safeActiveProtocol[msg.sender]).token();
        IERC20 _token = IERC20(IVault(safeActiveProtocol[msg.sender]).token());
        if(totalSupply() == 0)
        {
            _shares = _amount;
        }
        else
        {
            _shares = getMintValue(getDepositNAV(_tokenAddress, _amount));
        }
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _token.approve(safeActiveProtocol[msg.sender], _amount);
        IVault(safeActiveProtocol[msg.sender]).deposit(_amount);
        _mint(msg.sender, _shares);
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
        for (uint256 i = 0; i < protocolList.length; i++) 
        {
            if(IERC20(protocolList[i]).balanceOf(address(this)) > 0)
            {
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
        if(getStrategyNAV() == 0 || totalSupply() == 0)
        {
            return 0;
        }
        else
        {
            return (getStrategyNAV().mul(1e18)).div(totalSupply());
        }
    }



    function withdraw(uint256 _shares) 
        onlyRegisteredSafe
        external
    {
        require(balanceOf(msg.sender) >= _shares,"You don't have enough shares");
        address _tokenAddress = IVault(safeActiveProtocol[msg.sender]).token();
        IERC20 _token = IERC20(IVault(safeActiveProtocol[msg.sender]).token());
        address _protocolAddress = safeActiveProtocol[msg.sender];
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        uint256 strategyTokenValueInUSD = (_shares.mul(getStrategyNAV())).div(totalSupply());
        uint256 tokenCount = (strategyTokenValueInUSD.mul(1e18)).div(uint256(tokenUSD));
        uint256 protocolTokenUSD = IAPContract(APContract).getUSDPrice(_protocolAddress);
        uint256 _protocolShares = (strategyTokenValueInUSD.mul(1e18)).div(uint256(protocolTokenUSD));
        IVault(safeActiveProtocol[msg.sender]).withdraw(_protocolShares);
        _burn(msg.sender, _shares);
        _token.safeTransfer(msg.sender, tokenCount);
    }


    function _withdrawAllSafeBalance() private
    {
        IVault(safeActiveProtocol[msg.sender]).withdraw(_getProtocolBalanceForSafe());
    }


    // Withdraw all Protocol balance to Strategy
    function withdrawAll() public 
    {
        _withdrawAllSafeBalance();
    }

    // Withdraw all protocol assets to safe
    function withdrawAllToSafe() 
        public 
        onlyRegisteredSafe
    {
        uint256 SafeProtocolBalance = _getProtocolBalanceForSafe();
        _withdrawAllSafeBalance();
        address _protocolAddress = safeActiveProtocol[msg.sender];
        uint256 protocolTokenUSD = IAPContract(APContract).getUSDPrice(_protocolAddress);
        address _tokenAddress = IVault(safeActiveProtocol[msg.sender]).token();
        IERC20 _token = IERC20(IVault(safeActiveProtocol[msg.sender]).token());
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        uint256 tokensToGive = (SafeProtocolBalance.mul(uint256(protocolTokenUSD))).div(uint256(tokenUSD));
        _burn(msg.sender, balanceOf(msg.sender));
        _token.safeTransfer(msg.sender, tokensToGive);
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
        uint256 oldProtocolBalance = _getProtocolBalanceForSafe();
        withdrawAll();
        address _withdrawalAsset = IVault(safeActiveProtocol[msg.sender]).token();
        uint256 _balance = IERC20(_withdrawalAsset).balanceOf(address(this));

        if(_withdrawalAsset != IVault(_protocol).token())
        {
            // Token exchange and depositi logic
            (uint256 returnAmount, uint256[] memory distribution) = IExchange(oneInch).getExpectedReturn(_withdrawalAsset, IVault(_protocol).token(), 0, 0, 0);
            IExchange(oneInch).swap(_withdrawalAsset, IVault(_protocol).token(), 0, 0, distribution, 0);
            uint256 _depositAsset = IERC20(_protocol).balanceOf(address(this));
            // Deposit balance may need to recalculate, in the case of , temporary lock from monitor. Need to discuss with Team
            safeActiveProtocol[msg.sender] = _protocol;
            deposit(_depositAsset);
        }
        else
        {
            setActiveProtocol(_protocol);
            deposit(_balance);
        }
    }

    // function exec() onlyRegisteredSafe external {
    //     test="test passed";
    // }

}
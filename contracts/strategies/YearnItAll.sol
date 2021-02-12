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

contract YearnItAll is ERC20,ERC20Detailed {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
// yearn vault - need to confirm address

    address usdc = 0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;
    address oneInch = 0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;
    address APContract;

    address[] public protocolList;
    mapping(address => bool) private protocols;
    mapping(address => address) private safeEnabledProtocols;
    mapping(address => address) private ChainLinkFeed;
    event Expose(address);

    constructor(address _APContract, address[] memory _protocols) public ERC20Detailed("YRNITALL","Yearn it all",18){
        APContract = _APContract;
        // initialise yearn vaults;
        for (uint256 i = 0; i < _protocols.length; i++) 
        {
            protocols[_protocols[i]] = true;
            protocolList.push(_protocols[i]);
        }
    }

    

   function deposit(uint256 _amount) public {
    //    Should we use transfer/ or approve directly
        uint256 _shares;
        address _tokenAddress = IVault(safeEnabledProtocols[msg.sender]).token();
        IERC20 _token = IERC20(IVault(safeEnabledProtocols[msg.sender]).token());
        if(totalSupply() == 0)
        {
            _shares = _amount;
        }
        else
        {
            _shares = getMintValue(getDepositNav(_tokenAddress, _amount));
        }
        _token.transferFrom(msg.sender, address(this), _amount);
        _token.approve(safeEnabledProtocols[msg.sender], _amount);
        IVault(safeEnabledProtocols[msg.sender]).deposit(_amount);
        // Need to add NAV logic to the vault
        _mint(msg.sender, _shares);

        emit Expose(msg.sender);
    }

    //Function to find the Token to be minted for a deposit
    function getMintValue(uint256 depositNAV)
        public
        view
        returns (uint256)
    {
        // return depositNAV.div(tokenValueInUSD());
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
                (int256 tokenUSD, ,uint8 decimals) = IAPContract(APContract).getUSDPrice(protocolList[i]);
                strategyNAV += (IERC20(protocolList[i]).balanceOf(address(this)).mul(uint256(tokenUSD))).div(10 ** uint256(decimals));       
            }
        }
        return strategyNAV;
    }

    function getDepositNav(address _tokenAddress, uint256 _amount)
        view
        public
        returns (uint256)
    {
        (int256 tokenUSD, ,uint8 decimals) = IAPContract(APContract).getUSDPrice(_tokenAddress);
        return (_amount.mul(uint256(tokenUSD))).div(10 ** uint256(decimals));
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



    function withdraw(uint256 _shares) external
    {
        require(balanceOf(msg.sender) >= _shares,"You don't have enough shares");

        address _tokenAddress = IVault(safeEnabledProtocols[msg.sender]).token();
        IERC20 _token = IERC20(IVault(safeEnabledProtocols[msg.sender]).token());

        address _protocolAddress = safeEnabledProtocols[msg.sender];

        (int256 tokenUSD, ,uint8 tokenDecimal) = IAPContract(APContract).getUSDPrice(_tokenAddress);
        uint256 strategyTokenValueInUSD = (_shares.mul(getStrategyNAV())).div(totalSupply());

        uint256 tokenCount = (strategyTokenValueInUSD.mul(10 ** uint256(tokenDecimal))).div(uint256(tokenUSD));

        (int256 protocolTokenUSD, ,uint8 protocolDecimal) = IAPContract(APContract).getUSDPrice(_protocolAddress);

        uint256 _protocolShares = (strategyTokenValueInUSD.mul(10 ** uint256(protocolDecimal))).div(uint256(protocolTokenUSD));

        IVault(safeEnabledProtocols[msg.sender]).withdraw(_protocolShares);
        _burn(msg.sender, _shares);
        _token.transfer(msg.sender, tokenCount);
    }


    function _withdrawAllSafeBalance() private
    {
        IVault(safeEnabledProtocols[msg.sender]).withdraw(_getProtoColBalanceforSafe());
    }


    // Withdraw all Protocol balance to Strategy
    function withdrawAll() public 
    {
        _withdrawAllSafeBalance();
    }

    // Withdraw all protocol assets to safe
    function withdrawAllToSafe() public 
    {
        uint256 SafeProtocolBalance = _getProtoColBalanceforSafe();
        _withdrawAllSafeBalance();

        address _protocolAddress = safeEnabledProtocols[msg.sender];
        (int256 protocolTokenUSD, ,uint8 protocolDecimal) = IAPContract(APContract).getUSDPrice(_protocolAddress);

        address _tokenAddress = IVault(safeEnabledProtocols[msg.sender]).token();
        IERC20 _token = IERC20(IVault(safeEnabledProtocols[msg.sender]).token());

        (int256 tokenUSD, ,uint8 tokenDecimal) = IAPContract(APContract).getUSDPrice(_tokenAddress);

        uint256 tokensToGive = (SafeProtocolBalance.mul(uint256(protocolTokenUSD)).mul(10 ** uint256(tokenDecimal))).div(uint256(tokenUSD).mul(10 ** uint256(protocolDecimal)));

        _burn(msg.sender, balanceOf(msg.sender));
        _token.transfer(msg.sender, tokensToGive);
    }

    function want() external view returns (address)
    {
       return IVault(safeEnabledProtocols[msg.sender]).token();
    }


    function _getProtoColBalanceforSafe() 
        private 
        view 
        returns(uint256)
    {

        uint256 _shares = balanceOf(msg.sender);

        address _protocolAddress = safeEnabledProtocols[msg.sender];

        uint256 strategyTokenValueInUSD = (_shares.mul(getStrategyNAV())).div(totalSupply());

        (int256 protocolTokenUSD, ,uint8 protocolDecimal) = IAPContract(APContract).getUSDPrice(_protocolAddress);

        uint256 _protocolShares = (strategyTokenValueInUSD.mul(10 ** uint256(protocolDecimal))).div(uint256(protocolTokenUSD));

        return _protocolShares;

    }

    function changeProtocol(address _protocol) 
        external
    {
        require(protocols[_protocol], "Not an Enabled Protocols");
        require(safeEnabledProtocols[msg.sender] != address(0), "Not a registered Safe");
        uint256 oldProtocolBalance = _getProtoColBalanceforSafe();


        withdrawAll();
        address _withdrawalAsset = IVault(safeEnabledProtocols[msg.sender]).token();
        uint256 _balance = IERC20(_withdrawalAsset).balanceOf(address(this));

        if(_withdrawalAsset != IVault(_protocol).token())
        {
            // Token exchange and depositi logic

            (uint256 returnAmount, uint256[] memory distribution) = IExchange(oneInch).getExpectedReturn(_withdrawalAsset, IVault(_protocol).token(), 0, 0, 0);
            IExchange(oneInch).swap(_withdrawalAsset, IVault(_protocol).token(), 0, 0, distribution, 0);
            uint256 _depositAsset = IERC20(_protocol).balanceOf(address(this));
            // Deposit balance may need to recalculate, in the case of , temporary lock from monitor. Need to discuss with Team
            safeEnabledProtocols[msg.sender] = _protocol;
            deposit(_depositAsset);
        }
        else
        {
            safeEnabledProtocols[msg.sender] = _protocol;
            deposit(_balance);
        }
    }

    function setSafeActiveProtocol(address _protocol)
        public
    {
        safeEnabledProtocols[msg.sender] = _protocol;
    }

}
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

    constructor(address _APContract, address[] memory _protocols) public ERC20Detailed("YRNITALL","Yearn it all",18){
        APContract = _APContract;
        
        // initialise yearn vaults;
        for (uint256 i = 0; i < _protocols.length; i++) 
        {
            protocols[_protocols[i]] = true;
            protocolList.push(_protocols[i]);
        }
        // protocols[0x72aff7C29C28D659c571b5776c4e4c73eD8355Fb] = true;
        // protocols[0xf14f2e832AA11bc4bF8c66A456e2Cb1EaE70BcE9] = true;
        // protocols[0xf9a1522387Be6A2f3d442246f5984C508aa98F4e] = true;
    }

event Expose(address);
    

   function deposit(uint256 _amount) external {
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

     //Function to get the NAV of the vault
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



    function withdraw(uint256 _shares) external{
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


    function _withdrawAllSafeBalance() private{
        IVault(safeEnabledProtocols[msg.sender]).withdraw(_getProtoColBalanceforSafe());

    }


    // Withdraw all Protocl balance to Strategy
    function withdrawAll() external {
        _withdrawAllSafeBalance();
    }

    // Withdraw all protocol assets to safe
    function withdrawAllToSafe() external {
        uint256 SafeBalance=_getProtoColBalanceforSafe();
        _withdrawAllSafeBalance();
        _burn(msg.sender, IERC20(address(this)).balanceOf(msg.sender));
        IERC20(IVault(safeEnabledProtocols[msg.sender]).token()).transfer(msg.sender,SafeBalance);
    }

    function want() external view returns (address)
    {
       return IVault(safeEnabledProtocols[msg.sender]).token();
    }


    function _getProtoColBalanceforSafe() private view returns(uint256)
    {
        uint256 safeProtocolTokenUsd=1;
        uint256 safeShare=IERC20(address(this)).balanceOf(msg.sender);
        uint256 safeStrategyTokenUSD=1;

        // get balance from chainlink initially assumes as 1 USD
         return safeShare.mul(safeStrategyTokenUSD).div(safeProtocolTokenUsd);

    }

    function changeProtocol(address _protocol) external{
        require(protocols[_protocol]==true, "Not an Enabled Protocols");
        require(safeEnabledProtocols[msg.sender]!=address(0), "Not a registered Safe");
        this.withdrawAll();
        address _withdrawalAsset=IVault(safeEnabledProtocols[msg.sender]).token();
        
        uint256 _balance=IERC20(_withdrawalAsset).balanceOf(address(this));
        if(_withdrawalAsset!=IVault(_protocol).token())
        {
            // Token exchange and depositi logic

            (uint256 returnAmount, uint256[] memory distribution) = IExchange(oneInch).getExpectedReturn(_withdrawalAsset, IVault(_protocol).token(), 0, 0, 0);
            IExchange(oneInch).swap(_withdrawalAsset, IVault(_protocol).token(), 0, 0, distribution, 0);
            uint256 _depositAsset=IERC20(_protocol).balanceOf(address(this));
            // Deposit balance may need to recalculate, in the case of , temporary lock from monitor. Need to discuss with Team
            safeEnabledProtocols[msg.sender]=_protocol;
            this.deposit(_depositAsset);
        }
        else{
            safeEnabledProtocols[msg.sender]=_protocol;
            this.deposit(_balance);
            
        }
    }
    function setSafeActiveProtocol(address _protocol)
    public
    {
        safeEnabledProtocols[msg.sender] = _protocol;
    }

}
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
import "../interfaces/IHexUtils.sol";

contract LivaOneZapper is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // address curveZapper = 0x462991D18666c578F787e9eC0A74Cd18D2971E5F;
    // address zapOutContract = 0xB0880df8420974ef1b040111e5e0e95f05F8fee1;
    address curveZapper;
    address zapOutContract;
    address APContract;
    address owner;

    uint256 slippage = 100; //  1% slippage

    address[] public protocolList;
    mapping(address => bool) private protocols;

    struct Vault {
        bool isRegistered;
        address vaultActiveProtocol;
        mapping(address => uint256) protocolBalance;
    }

    mapping(address => Vault) vaults;

    modifier onlyRegisteredVault {
        require(vaults[msg.sender].isRegistered, "Not a registered Safe");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only permitted to owner");
        _;
    }

    function addProtocol(address _protocolAddress) public onlyOwner {
        require(_protocolAddress != address(0), "Zero address");
        protocolList.push(_protocolAddress);
    }

    constructor(
        address _APContract,
        address[] memory _protocols,
        address _curveZapper,
        address _zapOutContract
    ) public ERC20Detailed("LVAONE", "LIVA ONE", 18) {
        APContract = _APContract;
        for (uint256 i = 0; i < _protocols.length; i++) {
            protocols[_protocols[i]] = true;
            protocolList.push(_protocols[i]);
        }
        owner = msg.sender;
        curveZapper = _curveZapper;
        zapOutContract = _zapOutContract;
    }

    function setActiveProtocol(address _protocol) public onlyRegisteredVault {
        require(
            protocols[_protocol],
            "This protocol is not present in the strategy"
        );
        require(
            IAPContract(APContract)._isStrategyProtocolEnabled(
                msg.sender,
                address(this),
                _protocol
            ),
            "This protocol is not enabled for this safe"
        );
        vaults[msg.sender].vaultActiveProtocol = _protocol;
    }

    function setSlippage(uint256 _slippage) public onlyOwner {
        require(_slippage < 10000, "! percentage");
        slippage = _slippage;
    }

    function setAPContract(address _APContract) public onlyOwner {
        APContract = _APContract;
    }

    function getActiveProtocol(address _vaultAddress)
        public
        view
        returns (address)
    {
        require(vaults[_vaultAddress].isRegistered, "Not a registered Safe");
        return vaults[_vaultAddress].vaultActiveProtocol;
    }

    function registerSafe() public {
        Vault memory newVault =
            Vault({isRegistered: true, vaultActiveProtocol: address(0)});
        vaults[msg.sender] = newVault;
    }

    function deRegisterSafe() public onlyRegisteredVault {
        delete vaults[msg.sender];
    }

    function deposit(address _depositAsset, uint256 _amount)
        public
        onlyRegisteredVault
    {
        require(
            vaults[msg.sender].vaultActiveProtocol != address(0),
            "No active Protocol"
        );
        require(_amount > 0, "amount must be greater than 0");
        uint256 _shares;
        address _yVault = vaults[msg.sender].vaultActiveProtocol;
        uint256 amountDecimals =
            IHexUtils(IAPContract(APContract).stringUtils()).toDecimals(
                _depositAsset,
                _amount
            );

        IERC20(_depositAsset).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 yvtokenPriceInUSD =
            IAPContract(APContract).getUSDPrice(_yVault);
        uint256 strategyshareInUSD =
            amountDecimals
                .mul(IAPContract(APContract).getUSDPrice(_depositAsset))
                .div(1e18);
        uint256 equivalentyvTokenCount =
            IHexUtils(IAPContract(APContract).stringUtils()).fromDecimals(
                _yVault,
                (strategyshareInUSD.mul(1e18)).div(yvtokenPriceInUSD)
            );
        uint256 minReturnTokens =
            equivalentyvTokenCount -
                equivalentyvTokenCount.mul(slippage).div(10000);
        IERC20(_depositAsset).safeApprove(curveZapper, _amount);
        bytes memory swapData;
        uint256 returnAmount =
            IZapper(curveZapper).ZapInCurveVault(
                _depositAsset,
                _amount,
                _depositAsset,
                _yVault,
                minReturnTokens,
                address(0),
                swapData,
                address(0)
            );
        vaults[msg.sender].protocolBalance[_yVault] += returnAmount;

        if (balanceOf(msg.sender) == 0) _shares = amountDecimals;
        else _shares = getMintValue(getDepositNAV(_depositAsset, _amount));

        if (_shares > 0) _mint(msg.sender, _shares);
    }

    function getMintValue(uint256 depositNAV) public view returns (uint256) {
        if (vaults[msg.sender].isRegistered)
            return
                (depositNAV.mul(balanceOf(msg.sender))).div(getStrategyNAV());
        else return (depositNAV.mul(totalSupply())).div(getStrategyNAV());
    }

    function getStrategyNAV() public view returns (uint256) {
        uint256 strategyNAV;
        if (vaults[msg.sender].isRegistered) {
            address protocol = vaults[msg.sender].vaultActiveProtocol;
            uint256 protocolBalance =
                vaults[msg.sender].protocolBalance[protocol];
            if (protocolBalance > 0) {
                uint256 tokenUSD =
                    IAPContract(APContract).getUSDPrice(protocol);
                strategyNAV = (
                    IHexUtils(IAPContract(APContract).stringUtils())
                        .toDecimals(protocol, protocolBalance)
                        .mul(tokenUSD)
                )
                    .div(1e18);
            }
            return strategyNAV;
        } else {
            for (uint256 i = 0; i < protocolList.length; i++) {
                if (IERC20(protocolList[i]).balanceOf(address(this)) > 0) {
                    uint256 tokenUSD =
                        IAPContract(APContract).getUSDPrice(protocolList[i]);
                    uint256 balance =
                        IHexUtils(IAPContract(APContract).stringUtils())
                            .toDecimals(
                            protocolList[i],
                            IERC20(protocolList[i]).balanceOf(address(this))
                        );
                    strategyNAV += balance.mul(tokenUSD);
                }
            }
            return strategyNAV.div(1e18);
        }
    }

    function getDepositNAV(address _tokenAddress, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        return
            (
                IHexUtils(IAPContract(APContract).stringUtils())
                    .toDecimals(_tokenAddress, _amount)
                    .mul(tokenUSD)
            )
                .div(1e18);
    }

    function tokenValueInUSD() public view returns (uint256) {
        if (getStrategyNAV() == 0 || totalSupply() == 0) return 0;
        if (vaults[msg.sender].isRegistered)
            return (getStrategyNAV().mul(1e18)).div(balanceOf(msg.sender));
        else return (getStrategyNAV().mul(1e18)).div(totalSupply());
    }

    function withdraw(uint256 _shares, address _withrawalAsset)
        public
        onlyRegisteredVault
        returns (address, uint256)
    {
        require(balanceOf(msg.sender) >= _shares, "Not enough shares");
        uint256 strategyTokenValueInUSD =
            (_shares.mul(getStrategyNAV())).div(balanceOf(msg.sender));
        address protocol = vaults[msg.sender].vaultActiveProtocol;
        uint256 protocolTokenUSD =
            IAPContract(APContract).getUSDPrice(protocol);
        uint256 protocolTokenCount =
            strategyTokenValueInUSD.mul(1e18).div(protocolTokenUSD);
        uint256 protocolTokensToWithdraw =
            IHexUtils(IAPContract(APContract).stringUtils()).fromDecimals(
                protocol,
                protocolTokenCount
            );
        uint256 minTokensCount =
            protocolTokensToWithdraw -
                protocolTokensToWithdraw.mul(slippage).div(10000);
        _burn(msg.sender, _shares);

        if (_withrawalAsset == address(0)) {
            IERC20(protocol).safeTransfer(msg.sender, protocolTokensToWithdraw);
            vaults[msg.sender].protocolBalance[
                protocol
            ] -= protocolTokensToWithdraw;
            return (protocol, protocolTokensToWithdraw);
        } else {
            IERC20(protocol).safeApprove(
                zapOutContract,
                protocolTokensToWithdraw
            );
            uint256 returnedTokens =
                IZapper(zapOutContract).ZapOut(
                    msg.sender,
                    _withrawalAsset,
                    protocol,
                    2,
                    protocolTokensToWithdraw,
                    minTokensCount
                );
            vaults[msg.sender].protocolBalance[
                protocol
            ] -= protocolTokensToWithdraw;
            return (_withrawalAsset, returnedTokens);
        }
    }

    function _changeProtocol(address _protocol) private {
        address currentProtocol = vaults[msg.sender].vaultActiveProtocol;

        uint256 currentProtocolBalance =
            vaults[msg.sender].protocolBalance[currentProtocol];

        uint256 strategyTokenValueInUSD = getStrategyNAV();

        uint256 newProtocolTokenCount =
            strategyTokenValueInUSD.mul(1e18).div(
                IAPContract(APContract).getUSDPrice(_protocol)
            );

        uint256 expectedTokens =
            IHexUtils(IAPContract(APContract).stringUtils()).fromDecimals(
                _protocol,
                newProtocolTokenCount
            );

        uint256 minTokens =
            expectedTokens - expectedTokens.mul(slippage).div(10000);

        vaults[msg.sender].protocolBalance[currentProtocol] = 0;

        IERC20(currentProtocol).approve(curveZapper, currentProtocolBalance);
        bytes memory swapData;
        uint256 returnAmount =
            IZapper(curveZapper).ZapInCurveVault(
                currentProtocol,
                currentProtocolBalance,
                currentProtocol,
                _protocol,
                minTokens,
                address(0),
                swapData,
                address(0)
            );
        vaults[msg.sender].vaultActiveProtocol = _protocol;
        vaults[msg.sender].protocolBalance[_protocol] += returnAmount;
    }

    function withdrawAllToSafe(address _withdrawalToken)
        public
        onlyRegisteredVault
        returns (address, uint256)
    {
        return withdraw(balanceOf(msg.sender), _withdrawalToken);
    }

    function want() external view onlyRegisteredVault returns (address) {
        return IVault(vaults[msg.sender].vaultActiveProtocol).token();
    }

    function changeProtocol(address _protocol) external onlyRegisteredVault {
        require(protocols[_protocol], "protocol not present");
        require(
            IAPContract(APContract)._isStrategyProtocolEnabled(
                msg.sender,
                address(this),
                _protocol
            ),
            "protocol not enabled for vault"
        );
        _changeProtocol(_protocol);
    }

    function inCaseTokenGetsStuck(address _tokenAddres) public onlyOwner {
        IERC20(_tokenAddres).safeTransfer(
            msg.sender,
            IERC20(_tokenAddres).balanceOf(address(this))
        );
    }
}

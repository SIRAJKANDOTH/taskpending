// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAPContract.sol";
import "../interfaces/ICrvAddressProvider.sol";
import "../interfaces/ICrvRegistry.sol";
import "../interfaces/yearn/IVault.sol";
import "../interfaces/IExchange.sol";
import "../interfaces/IHexUtils.sol";
import "../interfaces/ICrvPool.sol";
import "../interfaces/IExchangeRegistry.sol";

contract EuroPlus is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public APContract;
    address public owner;
    address private crvAddressProvider =
        0x0000000022D53366457F9d5E68Ec105046FC4383;
    uint256 public slippage = 10; //  0.1% slippage
    uint256 public slippageSwap = 50; //  0.5% slippage on swap
    address public protocol;
    uint256 public protocolBalance;
    mapping(address => bool) poolTokens;
    mapping(address => bool) isRegistered;

    modifier onlyRegisteredVault() {
        require(isRegistered[msg.sender], "Not a registered Safe");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only permitted to owner");
        _;
    }

    constructor(
        address _APContract,
        address _protocol,
        address[] memory _poolTokens
    ) public ERC20Detailed("EURPLUS", "EURO PLUS", 18) {
        APContract = _APContract;
        protocol = _protocol;
        for (uint256 i = 0; i < _poolTokens.length; i++) {
            poolTokens[_poolTokens[i]] = true;
        }
        owner = msg.sender;
    }

    /// @dev Function to set yearn protocols to the strategy.
    /// @param _protocol Address of the yearn protocol.
    function setProtocol(
        address _protocol,
        address[] calldata addPoolTokens,
        address[] calldata removePoolTokens
    ) external onlyOwner {
        require(_protocol != address(0), "Zero address");
        protocol = _protocol;
        for (uint256 i = 0; i < addPoolTokens.length; i++) {
            poolTokens[addPoolTokens[i]] = true;
        }
        for (uint256 i = 0; i < removePoolTokens.length; i++) {
            poolTokens[removePoolTokens[i]] = false;
        }
    }

    /// @dev Function that returns the address of the Curve Registry contract.
    function getRegistry() internal view returns (address) {
        return ICrvAddressProvider(crvAddressProvider).get_registry();
    }

    /// @dev Function to set slippage settings when performing exchanges.
    /// @param _slippageSwap Slippage value.
    function setSlippageSwap(uint256 _slippageSwap) external onlyOwner {
        require(_slippageSwap < 10000, "! percentage");
        slippageSwap = _slippageSwap;
    }

    /// @dev Function to set slippage settings when interacting with Curve pools.
    /// @param _slippage Slippage value.
    function setSlippage(uint256 _slippage) external onlyOwner {
        require(_slippage < 10000, "! percentage");
        slippage = _slippage;
    }

    /// @dev Function to set the address of the Yieldster APS.
    /// @param _APContract Address of the APS Contract.
    function setAPContract(address _APContract) external onlyOwner {
        APContract = _APContract;
    }

    /// @dev Function to subscribe a new vault to the strategy.
    function registerSafe() external {
        isRegistered[msg.sender] = true;
    }

    /// @dev Function to unsubscribe a vault from the strategy.
    function deRegisterSafe() external onlyRegisteredVault {
        isRegistered[msg.sender] = false;
    }

    /// @dev Function to approve a token.
    /// @param _token Address of the token.
    /// @param _spender Address of the spender.
    /// @param _amount Amount of tokens to approve.
    function _approveToken(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _spender) > 0) {
            IERC20(_token).safeApprove(_spender, 0);
            IERC20(_token).safeApprove(_spender, _amount);
        } else IERC20(_token).safeApprove(_spender, _amount);
    }

    function depositToPool(
        address[2] memory poolAssets,
        uint256[2] memory poolAmounts,
        uint256 minPoolTokens
    ) internal returns (uint256) {
        address underlying = IVault(protocol).token();
        address pool = ICrvRegistry(getRegistry()).get_pool_from_lp_token(
            underlying
        );

        for (uint256 i = 0; i < poolAssets.length; i++) {
            IERC20(poolAssets[i]).safeApprove(pool, poolAmounts[i]);
        }

        uint256 underlyingBefore = IERC20(underlying).balanceOf(address(this));
        ICrvPool(pool).add_liquidity(poolAmounts, minPoolTokens);
        uint256 underlyingAfter = IERC20(underlying).balanceOf(address(this));
        return underlyingAfter - underlyingBefore;
    }

    /// @dev Function to handle tokens other than DAI | USDC | USDT.
    /// @param otherAssets Address List of tokens.
    /// @param otherAmounts Amount List of tokens.
    function handleOtherAssets(
        address[] memory otherAssets,
        uint256[] memory otherAmounts
    ) internal returns (uint256, uint256) {
        uint256 underlyingTokens;
        uint256 yVTokens;
        uint256 exchangeUnderlying;
        address underlying = IVault(protocol).token();
        for (uint256 i = 0; i < otherAssets.length; i++) {
            if (otherAssets[i] == underlying)
                underlyingTokens += otherAmounts[i];
            else if (otherAssets[i] == protocol) yVTokens += otherAmounts[i];
            else {
                exchangeUnderlying += exchangeToken(
                    otherAssets[i],
                    underlying,
                    otherAmounts[i]
                );
            }
        }
        return (underlyingTokens + exchangeUnderlying, yVTokens);
    }

    /// @dev Function to deposit LP tokens to Yearn Vault.
    /// @param yVault Address of the yearn vault.
    /// @param amount Amount of LP tokens to deposit.
    function depositToYearnVault(address yVault, uint256 amount)
        internal
        returns (uint256)
    {
        address underlying = IVault(yVault).token();
        _approveToken(underlying, yVault, amount);
        uint256 yVaultTokens = IVault(yVault).deposit(amount);
        return yVaultTokens;
    }

    /// @dev Function to exchange from one token to another.
    /// @param fromToken Address of from token.
    /// @param toToken Address of target token.
    /// @param amount Amount of tokens to exchange.
    function exchangeToken(
        address fromToken,
        address toToken,
        uint256 amount
    ) internal returns (uint256) {
        uint256 exchangeReturn;
        IExchangeRegistry exchangeRegistry = IExchangeRegistry(
            IAPContract(APContract).exchangeRegistry()
        );
        address exchange = exchangeRegistry.getPair(fromToken, toToken);
        require(exchange != address(0), "Exchange pair not present");

        uint256 fromTokenUSD = IAPContract(APContract).getUSDPrice(fromToken);
        uint256 toTokenUSD = IAPContract(APContract).getUSDPrice(toToken);
        uint256 fromTokenAmountDecimals = IHexUtils(
            IAPContract(APContract).stringUtils()
        ).toDecimals(fromToken, amount);

        uint256 expectedToTokenDecimal = (
            fromTokenAmountDecimals.mul(fromTokenUSD)
        ).div(toTokenUSD);
        uint256 expectedToToken = IHexUtils(
            IAPContract(APContract).stringUtils()
        ).fromDecimals(toToken, expectedToTokenDecimal);
        uint256 minReturn = expectedToToken - //SLIPPAGE
            expectedToToken.mul(slippageSwap).div(10000);

        _approveToken(fromToken, exchange, amount);
        exchangeReturn = IExchange(exchange).swap(
            fromToken,
            toToken,
            amount,
            minReturn
        );
        return exchangeReturn;
    }

    /// @dev Function to handle strategy deposit function.
    /// @param data Encoded parameters to be used.
    function handleDeposit(bytes memory data) internal returns (uint256) {
        uint256 yVaultUnderlyingReturn;
        uint256 otherYVUnderlyingReturn;
        uint256 _yVToken;
        (
            address[2] memory poolAssets,
            uint256[2] memory poolAmounts,
            uint256 minPoolTokens,
            address[] memory otherAssets,
            uint256[] memory otherAmounts
        ) = abi.decode(
                data,
                (address[2], uint256[2], uint256, address[], uint256[])
            );

        if (poolAssets.length > 0) {
            yVaultUnderlyingReturn = depositToPool(
                poolAssets,
                poolAmounts,
                minPoolTokens
            );
        }
        if (otherAssets.length > 0) {
            (otherYVUnderlyingReturn, _yVToken) = handleOtherAssets(
                otherAssets,
                otherAmounts
            );
        }

        uint256 yVTokens = depositToYearnVault(
            protocol,
            yVaultUnderlyingReturn + otherYVUnderlyingReturn
        );
        return _yVToken + yVTokens;
    }

    /// @dev Function to deposit into strategy.
    /// @param _depositAssets Address List of total assets being deposited.
    /// @param _amounts Amounts List of total assets being deposited.
    /// @param data Encoded parameters to be used.
    function deposit(
        address[] calldata _depositAssets,
        uint256[] calldata _amounts,
        bytes calldata data
    ) external onlyRegisteredVault {
        address underlying = IVault(protocol).token();
        address pool = ICrvRegistry(getRegistry()).get_pool_from_lp_token(
            underlying
        );
        require(pool != address(0), "pool not present");
        for (uint256 i = 0; i < _depositAssets.length; i++) {
            if (_amounts[i] > 0) {
                IERC20(_depositAssets[i]).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _amounts[i]
                );
            }
        }

        uint256 yVTokens = handleDeposit(data);
        uint256 _shares;
        if (totalSupply() == 0)
            _shares = IHexUtils(IAPContract(APContract).stringUtils())
                .toDecimals(protocol, yVTokens);
        else _shares = getMintValue(getDepositNAV(protocol, yVTokens));
        protocolBalance += yVTokens;

        if (_shares > 0) _mint(msg.sender, _shares);
    }

    /// @dev Function to calculate the strategy tokens to be minted for given nav.
    /// @param depositNAV NAV for the amount.
    function getMintValue(uint256 depositNAV) public view returns (uint256) {
        return (depositNAV.mul(totalSupply())).div(getStrategyNAV());
    }

    /// @dev Function to calculate the NAV of strategy for a subscribed vault | if the msg.sender is
    ///not subscribed vault then overall NAV of the strategy is returned.
    function getStrategyNAV() public view returns (uint256) {
        if (protocolBalance > 0) {
            uint256 tokenUSD = IAPContract(APContract).getUSDPrice(protocol);
            uint256 balance = IHexUtils(IAPContract(APContract).stringUtils())
                .toDecimals(protocol, protocolBalance);
            return (balance.mul(tokenUSD)).div(1e18);
        } else return 0;
    }

    /// @dev Function to calculate the NAV of a given token and amount.
    /// @param _tokenAddress Address of the deposit token.
    /// @param _amount Amount of deposit token.
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
            ).div(1e18);
    }

    /// @dev Function to calculate the token value of strategy for a subscribed Safe, if msg.sender is
    /// not a subscribed safe then the overall token value is returned.
    function tokenValueInUSD() public view returns (uint256) {
        if (getStrategyNAV() == 0 || totalSupply() == 0) return 0;
        else return (getStrategyNAV().mul(1e18)).div(totalSupply());
    }

    /// @dev Function to withdraw strategy shares.
    /// @param _shares amount of strategy shares to withdraw.
    /// @param _withrawalAsset Address of the prefered withdrawal asset.
    function withdraw(uint256 _shares, address _withrawalAsset)
        public
        onlyRegisteredVault
        returns (
            bool,
            address,
            uint256
        )
    {
        require(balanceOf(msg.sender) >= _shares, "Not enough shares");
        uint256 strategyTokenValueInUSD = (_shares.mul(getStrategyNAV())).div(
            totalSupply()
        );
        address underlying = IVault(protocol).token();
        uint256 protocolTokenUSD = IAPContract(APContract).getUSDPrice(
            protocol
        );
        uint256 protocolTokenCount = strategyTokenValueInUSD.mul(1e18).div(
            protocolTokenUSD
        );
        uint256 protocolTokensToWithdraw = IHexUtils(
            IAPContract(APContract).stringUtils()
        ).fromDecimals(protocol, protocolTokenCount);
        _burn(msg.sender, _shares);
        protocolBalance -= protocolTokensToWithdraw;

        if (_withrawalAsset == address(0) || _withrawalAsset == protocol) {
            IERC20(protocol).safeTransfer(msg.sender, protocolTokensToWithdraw);
            return (true, protocol, protocolTokensToWithdraw);
        } else {
            uint256 underlyingAmount = IVault(protocol).withdraw(
                protocolTokensToWithdraw
            );
            if (_withrawalAsset == underlying) {
                IERC20(underlying).safeTransfer(msg.sender, underlyingAmount);
                return (true, underlying, underlyingAmount);
            } else if (poolTokens[_withrawalAsset]) {
                uint256 returnTokens = withdrawFromPool(
                    _withrawalAsset,
                    underlying,
                    underlyingAmount
                );
                IERC20(_withrawalAsset).safeTransfer(msg.sender, returnTokens);
                return (true, _withrawalAsset, returnTokens);
            } else {
                uint256 withdrawalTokens = exchangeToken(
                    underlying,
                    _withrawalAsset,
                    underlyingAmount
                );
                IERC20(_withrawalAsset).safeTransfer(
                    msg.sender,
                    withdrawalTokens
                );
                return (true, _withrawalAsset, withdrawalTokens);
            }
        }
    }

    function withdrawFromPool(
        address toToken,
        address lpToken,
        uint256 amount
    ) internal returns (uint256) {
        uint256 toTokenReturn;
        address pool = ICrvRegistry(getRegistry()).get_pool_from_lp_token(
            lpToken
        );

        uint256[2] memory poolNCoins = ICrvRegistry(getRegistry()).get_n_coins(
            pool
        );
        address[8] memory poolCoins = ICrvRegistry(getRegistry()).get_coins(
            pool
        );
        uint256 index = poolNCoins[0];

        uint256 lpTokenUSD = IAPContract(APContract).getUSDPrice(lpToken);
        uint256 toTokenUSD = IAPContract(APContract).getUSDPrice(toToken);
        uint256 lpTokenAmountDecimals = IHexUtils(
            IAPContract(APContract).stringUtils()
        ).toDecimals(lpToken, amount);

        uint256 expectedToTokenDecimal = (lpTokenAmountDecimals.mul(lpTokenUSD))
            .div(toTokenUSD);
        uint256 expectedToToken = IHexUtils(
            IAPContract(APContract).stringUtils()
        ).fromDecimals(toToken, expectedToTokenDecimal);
        uint256 minReturn = expectedToToken - //SLIPPAGE
            expectedToToken.mul(slippage).div(10000);

        for (uint256 i = 0; i < index; i++) {
            if (poolCoins[i] == toToken) {
                toTokenReturn = ICrvPool(pool).remove_liquidity_one_coin(
                    amount,
                    int128(int256(i)),
                    minReturn
                );
            }
        }

        return toTokenReturn;
    }

    /// @dev Function to withdraw all shares from strategy.
    /// @param _withdrawalAsset Address of the prefered withdrawal asset.
    function withdrawAllToSafe(address _withdrawalAsset)
        external
        onlyRegisteredVault
        returns (
            bool,
            address,
            uint256
        )
    {
        return withdraw(balanceOf(msg.sender), _withdrawalAsset);
    }

    /// @dev Function to use in an Emergency, when a token gets stuck in the strategy.
    /// @param _tokenAddres Address of the token.
    function inCaseTokenGetsStuck(address _tokenAddres) external {
        require(
            msg.sender == IAPContract(APContract).yieldsterDAO(),
            "unauthorized"
        );
        IERC20(_tokenAddres).safeTransfer(
            msg.sender,
            IERC20(_tokenAddres).balanceOf(address(this))
        );
    }
}

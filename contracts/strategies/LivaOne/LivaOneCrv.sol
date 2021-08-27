// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "../interfaces/IAPContract.sol";
import "../interfaces/ICrvAddressProvider.sol";
import "../interfaces/ICrvRegistry.sol";
import "../interfaces/yearn/IVault.sol";
import "../interfaces/IExchange.sol";
import "../interfaces/IHexUtils.sol";
import "../interfaces/ICrvPool.sol";
import "../interfaces/ICrv3Pool.sol";
import "../interfaces/IExchangeRegistry.sol";

contract LivaOneCrv is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address APContract;
    address owner;
    address crv3Token = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address crvAddressProvider = 0x0000000022D53366457F9d5E68Ec105046FC4383;
    uint256 slippage = 10; //  0.1% slippage
    uint256 slippageSwap = 50; //  0.5% slippage on swap

    address[] public protocolList;
    mapping(address => bool) private protocols;

    struct Vault {
        bool isRegistered;
        address vaultActiveProtocol;
        mapping(address => uint256) protocolBalance;
    }

    mapping(address => Vault) vaults;

    modifier onlyRegisteredVault() {
        require(vaults[msg.sender].isRegistered, "Not a registered Safe");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only permitted to owner");
        _;
    }

    /// @dev Function to add new yearn protocols to the strategy.
    /// @param _protocol Address of the yearn protocol.
    function addProtocol(address _protocol) public onlyOwner {
        require(_protocol != address(0), "Zero address");
        protocols[_protocol] = true;
        protocolList.push(_protocol);
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

    /// @dev Function that returns the address of the Curve Registry contract.
    function getRegistry() internal view returns (address) {
        return ICrvAddressProvider(crvAddressProvider).get_registry();
    }

    /// @dev Function to initialy set new protocol for a subscribed Vault.
    /// @param _protocol Address of the yearn protocol.
    function setActiveProtocol(address _protocol)
        public
        onlyRegisteredVault
        returns (bool)
    {
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
        return false;
    }

    /// @dev Function to set slippage settings when performing exchanges.
    /// @param _slippageSwap Slippage value.
    function setSlippageSwap(uint256 _slippageSwap) public onlyOwner {
        require(_slippageSwap < 10000, "! percentage");
        slippageSwap = _slippageSwap;
    }

    /// @dev Function to set slippage settings when interacting with Curve pools.
    /// @param _slippage Slippage value.
    function setSlippage(uint256 _slippage) public onlyOwner {
        require(_slippage < 10000, "! percentage");
        slippage = _slippage;
    }

    /// @dev Function to set the address of the Yieldster APS.
    /// @param _APContract Address of the APS Contract.
    function setAPContract(address _APContract) public onlyOwner {
        APContract = _APContract;
    }

    /// @dev Function to get the protocol active for a subscribed vault.
    /// @param _vaultAddress Address of the vault.
    function getActiveProtocol(address _vaultAddress)
        public
        view
        returns (address)
    {
        require(vaults[_vaultAddress].isRegistered, "Not a registered Safe");
        return vaults[_vaultAddress].vaultActiveProtocol;
    }

    /// @dev Function to subscribe a new vault to the strategy.
    function registerSafe() public {
        Vault storage newVault = vaults[msg.sender];
        newVault.isRegistered = true;
    }

    /// @dev Function to unsubscribe a vault from the strategy.
    function deRegisterSafe() public onlyRegisteredVault {
        delete vaults[msg.sender];
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

    /// @dev Function to deposit DAI | USDC | USDT to Curve 3 Pool.
    /// @param assets Address List of the token.
    /// @param amounts Amount List of the token.
    /// @param min_mint_amount Min amount of 3Crv tokens expected.
    function depositToCurve3Pool(
        address[3] memory assets,
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) internal returns (uint256) {
        address pool = ICrvRegistry(getRegistry()).get_pool_from_lp_token(
            crv3Token
        );
        for (uint256 i = 0; i < assets.length; i++) {
            if (amounts[i] > 0) _approveToken(assets[i], pool, amounts[i]);
        }
        uint256 crv3TokenBefore = IERC20(crv3Token).balanceOf(address(this));
        ICrv3Pool(pool).add_liquidity(amounts, min_mint_amount);
        uint256 crv3TokenAfter = IERC20(crv3Token).balanceOf(address(this));
        uint256 returnAmount = crv3TokenAfter.sub(crv3TokenBefore);
        return returnAmount;
    }

    /// @dev Function to deposit 3Crv to Target Pool.
    /// @param amount Amount of 3Crv tokens.
    function deposit3CrvToTargetPool(uint256 amount)
        internal
        returns (uint256)
    {
        address yVault = vaults[msg.sender].vaultActiveProtocol;
        address underlying = IVault(yVault).token();
        address pool = ICrvRegistry(getRegistry()).get_pool_from_lp_token(
            underlying
        );
        uint256[2] memory poolNCoins = ICrvRegistry(getRegistry()).get_n_coins(
            pool
        );
        address[8] memory poolCoins = ICrvRegistry(getRegistry()).get_coins(
            pool
        );
        uint256 index = poolNCoins[0];
        uint256[2] memory amounts;

        for (uint256 i = 0; i < index; i++) {
            if (poolCoins[i] == crv3Token) amounts[i] = amount;
        }
        _approveToken(crv3Token, pool, amount);
        uint256 underlyingBefore = IERC20(underlying).balanceOf(address(this));
        uint256 crv3TokenUSD = IAPContract(APContract).getUSDPrice(crv3Token);
        uint256 crv3TokenAmountDecimals = IHexUtils(
            IAPContract(APContract).stringUtils()
        ).toDecimals(crv3Token, amount);
        uint256 underlyingUSD = IAPContract(APContract).getUSDPrice(underlying);
        uint256 expectedUnderlyingDecimal = (
            crv3TokenAmountDecimals.mul(crv3TokenUSD)
        ).div(underlyingUSD);
        uint256 expectedUnderlying = IHexUtils(
            IAPContract(APContract).stringUtils()
        ).fromDecimals(underlying, expectedUnderlyingDecimal);
        uint256 min_mint_amount = expectedUnderlying - //SLIPPAGE
            expectedUnderlying.mul(slippage).div(10000);
        ICrvPool(pool).add_liquidity(amounts, min_mint_amount);
        uint256 underlyingAfter = IERC20(underlying).balanceOf(address(this));
        return underlyingAfter.sub(underlyingBefore);
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

    /// @dev Function to handle tokens other than DAI | USDC | USDT.
    /// @param otherAssets Address List of tokens.
    /// @param otherAmounts Amount List of tokens.
    function handleOtherTokens(
        address[] memory otherAssets,
        uint256[] memory otherAmounts
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 underlyingTokens;
        uint256 yVTokens;
        uint256 crv3Tokens;
        address yVault = vaults[msg.sender].vaultActiveProtocol;
        address underlying = IVault(yVault).token();
        for (uint256 i = 0; i < otherAssets.length; i++) {
            if (otherAssets[i] == underlying)
                underlyingTokens += otherAmounts[i];
            else if (otherAssets[i] == yVault) yVTokens += otherAmounts[i];
            else if (otherAssets[i] == crv3Token) crv3Tokens += otherAmounts[i];
            else {
                crv3Tokens += exchangeToken(
                    otherAssets[i],
                    crv3Token,
                    otherAmounts[i]
                );
            }
        }
        return (underlyingTokens, crv3Tokens, yVTokens);
    }

    /// @dev Function to handle strategy deposit function.
    /// @param data Encoded parameters to be used.
    function handleDeposit(bytes memory data) internal returns (uint256) {
        uint256 crv3PoolReturn;
        uint256 yVaultUnderlyingReturn;
        uint256 otherYVUnderlyingReturn;
        uint256 other3CrvReturn;
        uint256 yVTokens;
        uint256 _yVToken;
        address yVault = vaults[msg.sender].vaultActiveProtocol;
        (
            address[3] memory crv3Assets,
            uint256[3] memory crv3Amounts,
            uint256 min3CrvMint,
            address[] memory otherAssets,
            uint256[] memory otherAmounts
        ) = abi.decode(
                data,
                (address[3], uint256[3], uint256, address[], uint256[])
            );
        if (min3CrvMint > 0) {
            crv3PoolReturn = depositToCurve3Pool(
                crv3Assets,
                crv3Amounts,
                min3CrvMint
            );
        }
        if (otherAssets.length > 0) {
            (
                otherYVUnderlyingReturn,
                other3CrvReturn,
                _yVToken
            ) = handleOtherTokens(otherAssets, otherAmounts);
        }
        if (crv3PoolReturn + other3CrvReturn > 0)
            yVaultUnderlyingReturn = deposit3CrvToTargetPool(
                crv3PoolReturn + other3CrvReturn
            );

        if (yVaultUnderlyingReturn + otherYVUnderlyingReturn > 0)
            yVTokens = depositToYearnVault(
                yVault,
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
        require(
            vaults[msg.sender].vaultActiveProtocol != address(0),
            "No active Protocol"
        );
        address yVault = vaults[msg.sender].vaultActiveProtocol;
        address underlying = IVault(yVault).token();
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
        if (balanceOf(msg.sender) == 0) _shares = yVTokens;
        else _shares = getMintValue(getDepositNAV(yVault, yVTokens));

        if (_shares > 0) _mint(msg.sender, _shares);
        vaults[msg.sender].protocolBalance[yVault] += yVTokens;
    }

    /// @dev Function to calculate the strategy tokens to be minted for given nav.
    /// @param depositNAV NAV for the amount.
    function getMintValue(uint256 depositNAV) public view returns (uint256) {
        if (vaults[msg.sender].isRegistered)
            return
                (depositNAV.mul(balanceOf(msg.sender))).div(getStrategyNAV());
        else return (depositNAV.mul(totalSupply())).div(getStrategyNAV());
    }

    /// @dev Function to calculate the NAV of strategy for a subscribed vault | if the msg.sender is
    ///not subscribed vault then overall NAV of the strategy is returned.
    function getStrategyNAV() public view returns (uint256) {
        uint256 strategyNAV;
        if (vaults[msg.sender].isRegistered) {
            address protocol = vaults[msg.sender].vaultActiveProtocol;
            uint256 protocolBalance = vaults[msg.sender].protocolBalance[
                protocol
            ];
            if (protocolBalance > 0) {
                uint256 tokenUSD = IAPContract(APContract).getUSDPrice(
                    protocol
                );
                strategyNAV = (
                    IHexUtils(IAPContract(APContract).stringUtils())
                        .toDecimals(protocol, protocolBalance)
                        .mul(tokenUSD)
                ).div(1e18);
            }
            return strategyNAV;
        } else {
            for (uint256 i = 0; i < protocolList.length; i++) {
                if (IERC20(protocolList[i]).balanceOf(address(this)) > 0) {
                    uint256 tokenUSD = IAPContract(APContract).getUSDPrice(
                        protocolList[i]
                    );
                    uint256 balance = IHexUtils(
                        IAPContract(APContract).stringUtils()
                    ).toDecimals(
                            protocolList[i],
                            IERC20(protocolList[i]).balanceOf(address(this))
                        );
                    strategyNAV += balance.mul(tokenUSD);
                }
            }
            return strategyNAV.div(1e18);
        }
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
        if (vaults[msg.sender].isRegistered)
            return (getStrategyNAV().mul(1e18)).div(balanceOf(msg.sender));
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
            balanceOf(msg.sender)
        );
        address protocol = vaults[msg.sender].vaultActiveProtocol;
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
        vaults[msg.sender].protocolBalance[
            protocol
        ] -= protocolTokensToWithdraw;

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
            } else {
                uint256 crv3Tokens = withdrawTo3CrvFromPool(
                    underlying,
                    underlyingAmount
                );
                if (_withrawalAsset == crv3Token) {
                    IERC20(crv3Token).safeTransfer(msg.sender, crv3Tokens);
                    return (true, crv3Token, crv3Tokens);
                }
                uint256 withdrawalTokens = exchangeToken(
                    crv3Token,
                    _withrawalAsset,
                    crv3Tokens
                );
                IERC20(_withrawalAsset).safeTransfer(
                    msg.sender,
                    withdrawalTokens
                );
                return (true, _withrawalAsset, withdrawalTokens);
            }
        }
    }

    /// @dev Function to remove Liquidity from Curve pool into 3Crv.
    /// @param lpToken Address of the LP token of the Curve pool.
    /// @param amount Amount of LP tokens.
    function withdrawTo3CrvFromPool(address lpToken, uint256 amount)
        internal
        returns (uint256)
    {
        address pool = ICrvRegistry(getRegistry()).get_pool_from_lp_token(
            lpToken
        );
        uint256 lpTokenUSD = IAPContract(APContract).getUSDPrice(lpToken);
        uint256 crv3TokenUSD = IAPContract(APContract).getUSDPrice(crv3Token);
        uint256 lpTokenAmountDecimals = IHexUtils(
            IAPContract(APContract).stringUtils()
        ).toDecimals(lpToken, amount);

        uint256 expectedCrv3TokenDecimal = (
            lpTokenAmountDecimals.mul(lpTokenUSD)
        ).div(crv3TokenUSD);
        uint256 expectedCrv3Token = IHexUtils(
            IAPContract(APContract).stringUtils()
        ).fromDecimals(crv3Token, expectedCrv3TokenDecimal);
        uint256 minReturn = expectedCrv3Token - //SLIPPAGE
            expectedCrv3Token.mul(slippage).div(10000);

        uint256 crv3Return = ICrvPool(pool).remove_liquidity_one_coin(
            amount,
            1,
            minReturn
        );
        return crv3Return;
    }

    /// @dev Function to change the protocol of a subscribed vault.
    /// @param _protocol Address of the new protocol.
    function _changeProtocol(address _protocol) private returns (bool) {
        address currentProtocol = vaults[msg.sender].vaultActiveProtocol;
        uint256 currentProtocolBalance = vaults[msg.sender].protocolBalance[
            currentProtocol
        ];
        vaults[msg.sender].vaultActiveProtocol = _protocol;
        vaults[msg.sender].protocolBalance[currentProtocol] = 0;
        uint256 oldUnderlyingAmount = IVault(currentProtocol).withdraw(
            currentProtocolBalance
        );
        address underlying = IVault(currentProtocol).token();
        uint256 crv3Tokens = withdrawTo3CrvFromPool(
            underlying,
            oldUnderlyingAmount
        );

        uint256 newUnderlyingAmount = deposit3CrvToTargetPool(crv3Tokens);
        uint256 newYVaultTokens = depositToYearnVault(
            _protocol,
            newUnderlyingAmount
        );
        vaults[msg.sender].protocolBalance[_protocol] += newYVaultTokens;
        return false;
    }

    /// @dev Function to withdraw all shares from strategy.
    /// @param _withdrawalAsset Address of the prefered withdrawal asset.
    function withdrawAllToSafe(address _withdrawalAsset)
        public
        onlyRegisteredVault
        returns (
            bool,
            address,
            uint256
        )
    {
        return withdraw(balanceOf(msg.sender), _withdrawalAsset);
    }

    /// @dev Function to change the protocol of a subscribed vault.
    /// @param _protocol Address of the new protocol.
    function changeProtocol(address _protocol)
        external
        onlyRegisteredVault
        returns (bool)
    {
        require(protocols[_protocol], "protocol not present");
        require(
            IAPContract(APContract)._isStrategyProtocolEnabled(
                msg.sender,
                address(this),
                _protocol
            ),
            "protocol not enabled for vault"
        );
        return _changeProtocol(_protocol);
    }

    /// @dev Function to use in an Emergency, when a token gets stuck in the strategy.
    /// @param _tokenAddres Address of the token.
    function inCaseTokenGetsStuck(address _tokenAddres) public onlyOwner {
        IERC20(_tokenAddres).safeTransfer(
            msg.sender,
            IERC20(_tokenAddres).balanceOf(address(this))
        );
    }
}

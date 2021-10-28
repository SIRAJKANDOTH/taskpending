// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/convex/IConvex.sol";
import "./interfaces/convex/IRewards.sol";
import "./interfaces/ICrvRegistry.sol";
import "./interfaces/ICrvAddressProvider.sol";
import "./interfaces/IExchangeRegistry.sol";
import "./interfaces/IExchange.sol";
import "./interfaces/ICrv3Pool.sol";
import "./interfaces/ICrvPool.sol";
import "./interfaces/IAPContract.sol";
import "./interfaces/IHexUtils.sol";

contract ConvexCRV is ERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public APContract;
    address public owner;
    address private crv3Token = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address private crvAddressProvider =
        0x0000000022D53366457F9d5E68Ec105046FC4383;
    uint256 slippage = 50; //  0.5% slippage
    uint256 slippageSwap = 50; //  0.5% slippage on swap

    uint256 public poolInfoID;
    uint256 public protocolBalance;
    address public baseToken;
    address public convexDeposit = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
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
        string memory _name,
        string memory _symbol,
        address _APContract,
        uint256 _poolInfoID,
        address _baseToken
    )
        ERC20(
            string(abi.encodePacked("yl-cvxfi", _symbol)),
            string(abi.encodePacked("yl-cvx", _name))
        )
    {
        APContract = _APContract;
        poolInfoID = _poolInfoID;
        baseToken = _baseToken;
        owner = msg.sender;
    }

    /// @dev Function to set convex pool to the strategy.
    /// @param _poolInfoID poolInfoID of the convex pool.
    /// @param _baseToken baseToken of the convex pool.

    function setProtocol(uint256 _poolInfoID, address _baseToken)
        external
        onlyOwner
    {
        require(_poolInfoID >= 0, "Cannot be zero");
        require(
            _poolInfoID < IConvex(convexDeposit).poolLength(),
            "Cannot be zero"
        );

        poolInfoID = _poolInfoID;
        baseToken = _baseToken;
    }

    /// @dev Function to change convex deposit contract
    /// @param _depositContractAddress Address of the new deposit contract

    function changeDepositContract(address _depositContractAddress)
        external
        onlyOwner
    {
        require(_depositContractAddress != address(0), "Zero address");
        convexDeposit = _depositContractAddress;
    }

    function getConvexBalance(address _vault) public view {
        (, , , address baseRewards, , ) = IConvex(convexDeposit).poolInfo(
            poolInfoID
        );
        // _approveToken(boosterDepositToken, baseRewards, amount);
        IRewards(baseRewards).balanceOf(_vault);
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

    /// @dev Function that returns the address of the Curve Registry contract.
    function getRegistry() internal view returns (address) {
        return ICrvAddressProvider(crvAddressProvider).get_registry();
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

    function calculateSlippage(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 slippagePercent
    ) internal view returns (uint256) {
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
            expectedToToken.mul(slippagePercent).div(10000);
        return minReturn;
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

        uint256 minReturn = calculateSlippage(
            fromToken,
            toToken,
            amount,
            slippageSwap
        );

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
            uint256,
            uint256
        )
    {
        (address crvLPToken, address boosterDepositToken, , , , ) = IConvex(
            convexDeposit
        ).poolInfo(poolInfoID);
        uint256 underlyingTokens;
        uint256 crv3Tokens;
        uint256 baseTokens;
        uint256 cvxTokens;
        for (uint256 i = 0; i < otherAssets.length; i++) {
            if (otherAssets[i] == crvLPToken)
                underlyingTokens += otherAmounts[i]; //asset3CRV Token
            else if (otherAssets[i] == baseToken)
                baseTokens += otherAmounts[i]; //baseAsset token
            else if (otherAssets[i] == crv3Token)
                crv3Tokens += otherAmounts[i]; //3CRV Token
            else if (otherAssets[i] == boosterDepositToken)
                cvxTokens += otherAmounts[i]; //cvx deposit tokens
            else {
                crv3Tokens += exchangeToken(
                    otherAssets[i],
                    crv3Token,
                    otherAmounts[i]
                );
            }
        }
        return (underlyingTokens, crv3Tokens, baseTokens, cvxTokens);
    }

    /// @dev Function to deposit 3Crv to Target Pool.
    /// @param crv3Amount Amount of 3Crv tokens.
    /// @param baseAmount Amount of base tokens.
    function depositToTargetPool(uint256 crv3Amount, uint256 baseAmount)
        internal
        returns (uint256)
    {
        (address crvLPToken, , , , , ) = IConvex(convexDeposit).poolInfo(
            poolInfoID
        );
        uint256 min_mint_amount;
        address pool = ICrvRegistry(getRegistry()).get_pool_from_lp_token(
            crvLPToken
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
            if (poolCoins[i] == crv3Token) {
                amounts[i] = crv3Amount;
                if (crv3Amount > 0) {
                    _approveToken(crv3Token, pool, crv3Amount);
                    min_mint_amount += calculateSlippage(
                        crv3Token,
                        crvLPToken,
                        crv3Amount,
                        slippage
                    );
                }
            } else if (poolCoins[i] == baseToken) {
                amounts[i] = baseAmount;
                if (baseAmount > 0) {
                    _approveToken(baseToken, pool, baseAmount);
                    min_mint_amount += calculateSlippage(
                        baseToken,
                        crvLPToken,
                        baseAmount,
                        slippage
                    );
                }
            }
        }
        uint256 underlyingBefore = IERC20(crvLPToken).balanceOf(address(this));
        ICrvPool(pool).add_liquidity(amounts, min_mint_amount);
        uint256 underlyingAfter = IERC20(crvLPToken).balanceOf(address(this));
        return underlyingAfter.sub(underlyingBefore);
    }

    /// @dev Function to Deposit to convex
    /// @param amount amount to deposit.
    function depositToCVX(uint256 amount) internal returns (uint256) {
        (address crvLPToken, , , , , ) = IConvex(convexDeposit).poolInfo(
            poolInfoID
        );
        _approveToken(crvLPToken, convexDeposit, amount);
        bool status = IConvex(convexDeposit).deposit(poolInfoID, amount, true);
        if (status) return amount;
        else revert("Deposit to CVX Failed");
    }

    /// @dev Function to stake to convex
    /// @param amount amount to deposit.
    function stakeToCVX(uint256 amount) internal returns (uint256) {
        (, address boosterDepositToken, , address baseRewards, , ) = IConvex(
            convexDeposit
        ).poolInfo(poolInfoID);
        // _approveToken(boosterDepositToken, baseRewards, amount);
        IRewards(baseRewards).stakeFor(address(this), amount);
        return amount;
    }

    /// @dev Function to handle strategy deposit function.
    /// @param data Encoded parameters to be used.
    function handleDeposit(bytes memory data) internal returns (uint256) {
        uint256 crv3PoolReturn;
        uint256 CVXUnderlyingReturn;
        uint256 otherCVXUnderlyingReturn;
        uint256 other3CrvReturn;
        uint256 otherBaseReturn;
        uint256 cvxTokens;
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
            crv3PoolReturn = depositToCurve3Pool( //3crv token
                crv3Assets,
                crv3Amounts,
                min3CrvMint
            );
        }

        if (otherAssets.length > 0) {
            (
                otherCVXUnderlyingReturn, //asset 3crv token
                other3CrvReturn, //3crv token
                otherBaseReturn, //asset token
                cvxTokens
            ) = handleOtherTokens(otherAssets, otherAmounts);
        }

        if (crv3PoolReturn + other3CrvReturn > 0 || otherBaseReturn > 0)
            CVXUnderlyingReturn = depositToTargetPool( //asset 3crv token
                crv3PoolReturn + other3CrvReturn,
                otherBaseReturn
            );

        uint256 CVXUnderlyingTokens = depositToCVX(
            CVXUnderlyingReturn + otherCVXUnderlyingReturn
        );

        uint256 cvxStakedReturns = stakeToCVX(cvxTokens);
        return cvxStakedReturns + CVXUnderlyingTokens;
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
        (address crvLPToken, , , , , bool shutdown) = IConvex(convexDeposit)
            .poolInfo(poolInfoID);

        require(shutdown != true, "Pool shutdown");
        address pool = ICrvRegistry(getRegistry()).get_pool_from_lp_token(
            crvLPToken
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

        uint256 cvxPoolTokens = handleDeposit(data);

        uint256 _shares;
        if (totalSupply() == 0) _shares = cvxPoolTokens;
        else _shares = getMintValue(getDepositNAV(crvLPToken, cvxPoolTokens));
        protocolBalance += cvxPoolTokens;

        if (_shares > 0) _mint(msg.sender, _shares);
    }

    /// @dev Function to calculate the strategy tokens to be minted for given nav.
    /// @param depositNAV NAV for the amount.
    function getMintValue(uint256 depositNAV) public view returns (uint256) {
        return (depositNAV.mul(totalSupply())).div(getStrategyNAV());
    }

    /// @dev Function to calculate the NAV of strategy for a subscribed vault | if the msg.sender is
    function getStrategyNAV() public view returns (uint256) {
        (address crvLPToken, , , , , ) = IConvex(convexDeposit).poolInfo(
            poolInfoID
        );

        if (protocolBalance > 0) {
            uint256 tokenUSD = IAPContract(APContract).getUSDPrice(crvLPToken); //TODO: CHECK AND CONFIRM
            uint256 balance = IHexUtils(IAPContract(APContract).stringUtils())
                .toDecimals(crvLPToken, protocolBalance);
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
}

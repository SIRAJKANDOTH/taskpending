// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "../storage/VaultStorage.sol";

contract Exchange is VaultStorage {
    /// @dev Function to exchange tokens to for a target token.
    /// @param targetToken Address of the target token.
    /// @param nav Nav to exchange.
    function exchangeSingleToken(address targetToken, uint256 nav)
        internal
        returns (uint256)
    {
        for (uint256 i = 0; i < assetList.length; i++) {
            if (assetList[i] != targetToken) {
                uint256 haveTokenUSD = IAPContract(APContract).getUSDPrice(
                    assetList[i]
                );
                if (
                    (
                        IHexUtils(IAPContract(APContract).stringUtils())
                            .toDecimals(
                                assetList[i],
                                tokenBalances.getTokenBalance(assetList[i])
                            )
                            .mul(haveTokenUSD)
                    ).div(1e18) >= nav
                ) {
                    uint256 amountToExchange = (nav.mul(1e18)).div(
                        haveTokenUSD
                    );
                    uint256 returnedTokenCount = swap(
                        assetList[i],
                        targetToken,
                        IHexUtils(IAPContract(APContract).stringUtils())
                            .fromDecimals(assetList[i], amountToExchange)
                    );
                    return returnedTokenCount;
                }
            }
        }
        return 0;
    }

    function calculateSlippage(
        address fromToken,
        address toToken,
        uint256 amount
    ) internal view returns (uint256) {
        uint256 slippage = IAPContract(APContract).getVaultSlippage();
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
            expectedToToken.mul(slippage).div(10000);
        return minReturn;
    }

    /// @dev Function to exchange tokens to for a target token.
    /// @param fromToken Address of the from token.
    /// @param toToken Address of the to token.
    /// @param amount Amount of tokens to exchange.
    function swap(
        address fromToken,
        address toToken,
        uint256 amount
    ) internal returns (uint256) {
        address exchange = IExchangeRegistry(
            IAPContract(APContract).exchangeRegistry()
        ).getPair(fromToken, toToken);
        _approveToken(fromToken, exchange, amount);
        uint256 minReturn = calculateSlippage(fromToken, toToken, amount);

        uint256 returnedTokenCount = IExchange(exchange).swap(
            fromToken,
            toToken,
            amount,
            minReturn
        );
        tokenBalances.setTokenBalance(
            fromToken,
            tokenBalances.getTokenBalance(fromToken).sub(amount)
        );
        tokenBalances.setTokenBalance(
            toToken,
            tokenBalances.getTokenBalance(toToken).add(returnedTokenCount)
        );
        return returnedTokenCount;
    }

    /// @dev Function to exchange tokens to for a target token.
    /// @param targetToken Address of the target token.
    /// @param nav Nav to exchange.
    function exchangeTokens(address targetToken, uint256 nav)
        public
        returns (uint256)
    {
        require(nav > 0, "non zero nav required");
        uint256 exchangedAmount = exchangeSingleToken(targetToken, nav);
        if (exchangedAmount > 0) {
            return exchangedAmount;
        } else {
            uint256 aquiredToken;
            uint256 currentNav;
            uint256 swappedAmount;

            for (uint256 i = 0; i < assetList.length; i++) {
                if (assetList[i] != targetToken) {
                    if (nav > currentNav) {
                        uint256 haveTokenUSD = IAPContract(APContract)
                            .getUSDPrice(assetList[i]);
                        uint256 haveTokenCount = tokenBalances.getTokenBalance(
                            assetList[i]
                        );
                        uint256 haveTokenNav = (
                            haveTokenUSD.mul(
                                IHexUtils(IAPContract(APContract).stringUtils())
                                    .toDecimals(assetList[i], haveTokenCount)
                            )
                        ).div(1e18);
                        if (haveTokenNav <= (nav - currentNav)) {
                            swappedAmount = swap(
                                assetList[i],
                                targetToken,
                                haveTokenCount
                            );
                            aquiredToken += swappedAmount;
                            currentNav += haveTokenNav;
                        } else {
                            uint256 navToExchange = nav - currentNav;
                            uint256 tokensToExchange = IHexUtils(
                                IAPContract(APContract).stringUtils()
                            ).fromDecimals(
                                    assetList[i],
                                    (navToExchange.mul(1e18)).div(haveTokenUSD)
                                );

                            swappedAmount = swap(
                                assetList[i],
                                targetToken,
                                tokensToExchange
                            );
                            aquiredToken += swappedAmount;
                            currentNav += navToExchange;
                        }
                    }
                    if (currentNav >= nav) return aquiredToken;
                }
            }
            return 0;
        }
    }
}

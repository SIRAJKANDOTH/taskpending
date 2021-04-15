// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "../../storage/VaultStorage.sol";

contract StockWithdraw
    is 
    VaultStorage
{

    function getStrategyWithHighestNav()
        view
        internal    
        returns(address, uint256)
    {
        address[] memory strategies = IAPContract(APContract).getVaultActiveStrategy(address(this));
        address strategyWithHighestNav;
        uint256 highestNav;
        for(uint256 i = 0; i < strategies.length; i++) {
            uint256 strategyNav = (IStrategy(strategies[i]).balanceOf(address(this)).mul(IStrategy(strategies[i]).tokenValueInUSD())).div(1e18);
            if(strategyNav > highestNav) {
                strategyWithHighestNav = strategies[i];
                highestNav = strategyNav;
            }
        }
        return (strategyWithHighestNav, highestNav);
    }

    function exchange(address toToken, uint256 nav)
        internal
        returns(uint256)
    {
        (bool success, bytes memory data) = IAPContract(APContract).yieldsterExchange().delegatecall(abi.encodeWithSignature("exchangeTokens(address,uint256)", toToken, nav));
        if(!success) revert("transaction failed");
        uint256 exchangeReturn = abi.decode(data, (uint256));
        return exchangeReturn;
    }

    function withdrawFromStrategy(address strategy, uint256 shares, address tokenPrefered)
        internal
        returns(uint256, uint256)
    {
        (address returnToken, uint256 returnAmount) = IStrategy(strategy).withdraw(shares, tokenPrefered);
        if(returnToken == tokenPrefered) {
            return (returnAmount, 0) ;
        } else {
            uint256 returnNav = (returnAmount.mul(IAPContract(APContract).getUSDPrice(returnToken))).div(1e18);
            return (0, returnNav);
        }
    }

    /// @dev Function to Withdraw assets from the Vault.
    /// @param _tokenAddress Address of the withdraw token.
    /// @param _shares Amount of Vault token shares.
    function withdraw(address _tokenAddress, uint256 _shares)
        public
    {
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        uint256 tokenCount = ((_shares.mul(getVaultNAV())).div(totalSupply()).mul(1e18)).div(tokenUSD);
        
        if(tokenCount <= tokenBalances.getTokenBalance(_tokenAddress)) {
            tokenBalances.setTokenBalance(_tokenAddress,tokenBalances.getTokenBalance(_tokenAddress).sub(tokenCount));
            _burn(msg.sender, _shares);
            IERC20(_tokenAddress).transfer(msg.sender,tokenCount);

        } else {
            uint256 needNav = ((tokenCount - (tokenBalances.getTokenBalance(_tokenAddress))).mul(tokenUSD)).div(1e18);
            uint256 haveNavInOtherTokens = getVaultNAVWithoutStrategyToken() - ((tokenBalances.getTokenBalance(_tokenAddress)).mul(tokenUSD)).div(1e18);
            uint256 towardsNeedWithSlippage = (tokenBalances.getTokenBalance(_tokenAddress));
            uint256 navFromStrategyWithdraw;

            if((_shares.mul(getVaultNAV())).div(totalSupply()) > getVaultNAVWithoutStrategyToken()) {
                address[] memory strategies = IAPContract(APContract).getVaultActiveStrategy(address(this));
                uint256 strategyWithdrawNav = (_shares.mul(getVaultNAV())).div(totalSupply()) - getVaultNAVWithoutStrategyToken();
                (address strategyWithHighestNav, uint256 highestNav) = getStrategyWithHighestNav();

                if(highestNav >= strategyWithdrawNav) {
                    (uint256 amount, uint256 returnNav) = withdrawFromStrategy(strategyWithHighestNav, (strategyWithdrawNav.mul(1e18)).div(IStrategy(strategyWithHighestNav).tokenValueInUSD()), _tokenAddress);
                    towardsNeedWithSlippage += amount;
                    navFromStrategyWithdraw += returnNav;
                } else {
                    uint256 currentNav;
                    for(uint256 i = 0; i < strategies.length; i++) {
                        if(currentNav < strategyWithdrawNav) {
                            uint256 strategyNav = (IStrategy(strategies[i]).balanceOf(address(this)).mul(IStrategy(strategies[i]).tokenValueInUSD())).div(1e18);
                            if(strategyNav <= (strategyWithdrawNav - currentNav)) {
                                (uint256 amount, uint256 returnNav) = withdrawFromStrategy(strategies[i], IStrategy(strategies[i]).balanceOf(address(this)), _tokenAddress);
                                towardsNeedWithSlippage += amount;
                                navFromStrategyWithdraw += returnNav;
                                currentNav += strategyNav;
                            } else {
                                uint256 toWithdrawNav = strategyNav - (strategyWithdrawNav - currentNav);
                                uint256 toWithdrawShares = (toWithdrawNav.mul(1e18)).div(IStrategy(strategies[i]).tokenValueInUSD());
                                (uint256 amount, uint256 returnNav) = withdrawFromStrategy(strategies[i], toWithdrawShares, _tokenAddress);
                                towardsNeedWithSlippage += amount;
                                navFromStrategyWithdraw += returnNav;
                                currentNav += toWithdrawNav;
                            }
                        }
                    }
                }

                uint256 exchangeReturn = exchange(_tokenAddress, haveNavInOtherTokens + navFromStrategyWithdraw);
                tokenBalances.setTokenBalance(_tokenAddress, tokenBalances.getTokenBalance(_tokenAddress).sub(exchangeReturn + towardsNeedWithSlippage));
                _burn(msg.sender, _shares);
                IERC20(_tokenAddress).transfer(msg.sender, exchangeReturn + towardsNeedWithSlippage);

            } else {
                uint256 exchangeReturn = exchange(_tokenAddress, needNav);
                tokenBalances.setTokenBalance(_tokenAddress, tokenBalances.getTokenBalance(_tokenAddress).sub(exchangeReturn + towardsNeedWithSlippage));
                _burn(msg.sender, _shares);
                IERC20(_tokenAddress).transfer(msg.sender, exchangeReturn + towardsNeedWithSlippage);
            }
        }
    }


    /// @dev Function to Withdraw shares from the Vault.
    /// @param _shares Amount of Vault token shares.
    function withdraw(uint256 _shares)
        public
    {
        uint256 safeTotalSupply = totalSupply();
        _burn(msg.sender, _shares); 
        address[] memory strategies;

        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 safeStrategyBalance = IStrategy(strategies[i]).balanceOf(address(this));
            if(safeStrategyBalance > 0) {
                uint256 strategyShares = (_shares.mul(safeStrategyBalance)).div(safeTotalSupply); 
                (address returnToken, uint256 returnAmount) = IStrategy(strategies[i]).withdraw(strategyShares, address(0));
                IERC20(returnToken).transfer(msg.sender, returnAmount);
            }
        }

        for(uint256 i = 0; i < assetList.length; i++ ){   
            IERC20 token = IERC20(assetList[i]);
            if(tokenBalances.getTokenBalance(assetList[i]) > 0){
                uint256 tokensToGive = (_shares.mul(tokenBalances.getTokenBalance(assetList[i]))).div(safeTotalSupply);
                tokenBalances.setTokenBalance(assetList[i],tokenBalances.getTokenBalance(assetList[i]).sub(tokensToGive));
                token.transfer(msg.sender, tokensToGive);
            }
        }
    }
}
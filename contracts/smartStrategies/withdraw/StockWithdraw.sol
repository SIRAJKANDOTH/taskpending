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
            uint256 returnNav = (IHexUtils(IAPContract(APContract).stringUtils()).toDecimals(returnToken,returnAmount).mul(IAPContract(APContract).getUSDPrice(returnToken))).div(1e18);
            return (0, returnNav);
        }
    }

    function withdrawFromMultipleStrategy(uint256 navToWithdraw, address _tokenAddress)
        internal
        returns(uint256, uint256)
    {
        uint256 currentNav; uint256 towardsNeedWithSlippage; uint256 navFromStrategyWithdraw;
        address[] memory strategies = IAPContract(APContract).getVaultActiveStrategy(address(this));
        for(uint256 i = 0; i < strategies.length; i++) {
            if(currentNav < navToWithdraw) {
                uint256 strategyNav = (IStrategy(strategies[i]).balanceOf(address(this)).mul(IStrategy(strategies[i]).tokenValueInUSD())).div(1e18);
                if(strategyNav <= (navToWithdraw - currentNav)) {
                    (uint256 amount, uint256 returnNav) = withdrawFromStrategy(strategies[i], IStrategy(strategies[i]).balanceOf(address(this)), _tokenAddress);
                    towardsNeedWithSlippage += amount;
                    navFromStrategyWithdraw += returnNav;
                    currentNav += strategyNav;
                } else {
                    uint256 toWithdrawNav = strategyNav - (navToWithdraw - currentNav);
                    uint256 toWithdrawShares = (toWithdrawNav.mul(1e18)).div(IStrategy(strategies[i]).tokenValueInUSD());
                    (uint256 amount, uint256 returnNav) = withdrawFromStrategy(strategies[i], toWithdrawShares, _tokenAddress);
                    towardsNeedWithSlippage += amount;
                    navFromStrategyWithdraw += returnNav;
                    currentNav += toWithdrawNav;
                }
            }
        }
        return (towardsNeedWithSlippage, navFromStrategyWithdraw);
    }

    function updateAndTransferTokens(address tokenAddress, uint256 updatedBalance, uint256 shares, uint256 transferAmount)
        internal
    {
        tokenBalances.setTokenBalance(tokenAddress, tokenBalances.getTokenBalance(tokenAddress).sub(updatedBalance));
        _burn(msg.sender, shares);
        IERC20(tokenAddress).transfer(msg.sender, transferAmount);
    }

    function strategyWithdraw(address _tokenAddress, uint256 _shares) 
        internal
    {
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        uint256 towardsNeedWithSlippage = (tokenBalances.getTokenBalance(_tokenAddress));
        uint256 haveNavInOtherTokens = getVaultNAVWithoutStrategyToken() - (IHexUtils(IAPContract(APContract).stringUtils()).toDecimals(_tokenAddress,tokenBalances.getTokenBalance(_tokenAddress)).mul(tokenUSD)).div(1e18);
        uint256 navFromStrategyWithdraw;
        uint256 strategyWithdrawNav = (_shares.mul(getVaultNAV())).div(totalSupply()) - getVaultNAVWithoutStrategyToken();
        (address strategyWithHighestNav, uint256 highestNav) = getStrategyWithHighestNav();

        if(highestNav >= strategyWithdrawNav) {
            (uint256 amount, uint256 returnNav) = withdrawFromStrategy(strategyWithHighestNav, (strategyWithdrawNav.mul(1e18)).div(IStrategy(strategyWithHighestNav).tokenValueInUSD()), _tokenAddress);
            towardsNeedWithSlippage += amount;
            navFromStrategyWithdraw += returnNav;
        } else {
            (uint256 returnTowardsNeedWithSlippage , uint256 returnNavFromStrategyWithdraw) =  withdrawFromMultipleStrategy(strategyWithdrawNav, _tokenAddress);
            towardsNeedWithSlippage += returnTowardsNeedWithSlippage;
            navFromStrategyWithdraw += returnNavFromStrategyWithdraw;
        }

        uint256 exchangeReturn = exchange(_tokenAddress, haveNavInOtherTokens + navFromStrategyWithdraw);
        updateAndTransferTokens(_tokenAddress, exchangeReturn + towardsNeedWithSlippage, _shares, exchangeReturn + towardsNeedWithSlippage );
    }

    function exchangeWithdraw(address _tokenAddress, uint256 _shares)
        internal
    {
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        uint256 tokenCount = ((_shares.mul(getVaultNAV())).div(totalSupply()).mul(1e18)).div(tokenUSD);
        uint256 towardsNeedWithSlippage = (tokenBalances.getTokenBalance(_tokenAddress));
        uint256 haveTokenCount = IHexUtils(IAPContract(APContract).stringUtils()).toDecimals(_tokenAddress, tokenBalances.getTokenBalance(_tokenAddress));
        uint256 exchangeReturn = exchange(_tokenAddress, ((tokenCount - haveTokenCount).mul(tokenUSD)).div(1e18));
        updateAndTransferTokens(_tokenAddress, exchangeReturn + towardsNeedWithSlippage, _shares, exchangeReturn + towardsNeedWithSlippage );
    }

    /// @dev Function to Withdraw assets from the Vault.
    /// @param _tokenAddress Address of the withdraw token.
    /// @param _shares Amount of Vault token shares.
    function withdraw(address _tokenAddress, uint256 _shares)
        public
    {
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        uint256 tokenCount = ((_shares.mul(getVaultNAV())).div(totalSupply()).mul(1e18)).div(tokenUSD);
        uint256 tokenCountDecimals = IHexUtils(IAPContract(APContract).stringUtils()).fromDecimals(_tokenAddress,tokenCount);
        
        if(tokenCountDecimals <= tokenBalances.getTokenBalance(_tokenAddress)) updateAndTransferTokens(_tokenAddress, tokenCountDecimals, _shares, tokenCountDecimals );
        else {
            if((_shares.mul(getVaultNAV())).div(totalSupply()) > getVaultNAVWithoutStrategyToken()) strategyWithdraw(_tokenAddress, _shares);
            else exchangeWithdraw(_tokenAddress, _shares);
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
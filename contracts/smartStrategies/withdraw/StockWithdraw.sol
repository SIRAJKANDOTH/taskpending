// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "../../storage/VaultStorage.sol";

contract StockWithdraw
    is 
    VaultStorage
{

    /// @dev Function to Withdraw assets from the Vault.
    /// @param _tokenAddress Address of the withdraw token.
    /// @param _shares Amount of Vault token shares.
    function withdraw(address _tokenAddress, uint256 _shares)
        public
    {
        uint256 tokenUSD = IAPContract(APContract).getUSDPrice(_tokenAddress);
        uint256 safeTokenValueUSD = (_shares.mul(getVaultNAV())).div(totalSupply());
        uint256 tokenCount = (safeTokenValueUSD.mul(1e18)).div(tokenUSD);
        
        if(tokenCount <= tokenBalances.getTokenBalance(_tokenAddress)) {
            tokenBalances.setTokenBalance(_tokenAddress,tokenBalances.getTokenBalance(_tokenAddress).sub(tokenCount));
            _burn(msg.sender, _shares);
            IERC20(_tokenAddress).transfer(msg.sender,tokenCount);

        } else {
            uint256 have = tokenBalances.getTokenBalance(_tokenAddress);
            uint256 need = tokenCount - have;
            uint256 needNav = (need.mul(tokenUSD)).div(1e18);
            uint256 haveNavInOtherTokens = getVaultNAVWithoutStrategyToken() - (have.mul(tokenUSD)).div(1e18);
            uint256 towardsNeedWithSlippage = have;
            uint256 navFromStrategyWithdraw;

            if(safeTokenValueUSD > getVaultNAVWithoutStrategyToken()) {
                address[] memory strategies = IAPContract(APContract).getVaultActiveStrategy(address(this));
                uint256 strategyWithdrawNav = safeTokenValueUSD - getVaultNAVWithoutStrategyToken();
                address strategyWithHighestNav;
                uint256 highestNav;
                for(uint256 i = 0; i < strategies.length; i++) {
                    uint256 strategyNav = (IStrategy(strategies[i]).balanceOf(address(this)).mul(IStrategy(strategies[i]).tokenValueInUSD())).div(1e18);
                    if(strategyNav > highestNav) {
                        strategyWithHighestNav = strategies[i];
                        highestNav = strategyNav;
                    }
                }

                if(highestNav >= strategyWithdrawNav) {
                    uint256 sharesToWithdraw = (strategyWithdrawNav.mul(1e18)).div(IStrategy(strategyWithHighestNav).tokenValueInUSD());
                    (address returnToken, uint256 returnAmount) = IStrategy(strategyWithHighestNav).withdraw(sharesToWithdraw, _tokenAddress);
                    if(returnToken == _tokenAddress) {
                        towardsNeedWithSlippage += returnAmount;
                    } else {
                        uint256 returnNav = (returnAmount.mul(IAPContract(APContract).getUSDPrice(returnToken))).div(1e18);
                        navFromStrategyWithdraw += returnNav;
                    }

                } else {
                    uint256 currentNav;
                    for(uint256 i = 0; i < strategies.length; i++) {
                        if(currentNav < strategyWithdrawNav) {
                            uint256 strategyNav = (IStrategy(strategies[i]).balanceOf(address(this)).mul(IStrategy(strategies[i]).tokenValueInUSD())).div(1e18);
                            if(strategyNav <= (strategyWithdrawNav - currentNav)) {
                                (address returnToken, uint256 returnAmount) = IStrategy(strategyWithHighestNav).withdraw(IStrategy(strategies[i]).balanceOf(address(this)), _tokenAddress);
                                if(returnToken == _tokenAddress) {
                                    have += returnAmount;
                                } else {
                                    uint256 returnNav = (returnAmount.mul(IAPContract(APContract).getUSDPrice(returnToken))).div(1e18);
                                    navFromStrategyWithdraw += returnNav;
                                }
                            } else {
                                uint256 toWithdrawNav = strategyNav - (strategyWithdrawNav - currentNav);
                                uint256 toWithdrawShares = (toWithdrawNav.mul(1e18)).div(IStrategy(strategies[i]).tokenValueInUSD());
                                (address returnToken, uint256 returnAmount) = IStrategy(strategyWithHighestNav).withdraw(toWithdrawShares, _tokenAddress);
                                if(returnToken == _tokenAddress) {
                                    have += returnAmount;
                                } else {
                                    uint256 returnNav = (returnAmount.mul(IAPContract(APContract).getUSDPrice(returnToken))).div(1e18);
                                    navFromStrategyWithdraw += returnNav;
                                }
                            }
                        }
                    }
                }
                (bool success, bytes memory data) = IAPContract(APContract).yieldsterExchange().delegatecall(abi.encodeWithSignature("exchangeToken(address,uint256)", _tokenAddress, haveNavInOtherTokens + navFromStrategyWithdraw));
                uint256 exchangeReturn = abi.decode(data, (uint256));
                if(!success) revert("transaction failed");

                tokenBalances.setTokenBalance(_tokenAddress, tokenBalances.getTokenBalance(_tokenAddress).sub(exchangeReturn + towardsNeedWithSlippage));
                _burn(msg.sender, _shares);
                IERC20(_tokenAddress).transfer(msg.sender, tokenCount);

            } else {
                (bool success, bytes memory data) = IAPContract(APContract).yieldsterExchange().delegatecall(abi.encodeWithSignature("exchangeToken(address,uint256)", _tokenAddress, needNav));
                uint256 exchangeReturn = abi.decode(data, (uint256));
                if(!success) revert("transaction failed");

                tokenBalances.setTokenBalance(_tokenAddress, tokenBalances.getTokenBalance(_tokenAddress).sub(exchangeReturn + towardsNeedWithSlippage));
                _burn(msg.sender, _shares);
                IERC20(_tokenAddress).transfer(msg.sender, tokenCount);
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
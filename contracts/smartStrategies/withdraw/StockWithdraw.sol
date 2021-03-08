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
        uint256 safeTokenVaulueInUSD = (_shares.mul(getVaultNAV())).div(totalSupply());
        uint256 tokenCount = (safeTokenVaulueInUSD.mul(1e18)).div(uint256(tokenUSD));
        
        if(tokenCount <= tokenBalances.getTokenBalance(_tokenAddress)){
            _burn(msg.sender, _shares);
            IERC20(_tokenAddress).transfer(msg.sender,tokenCount);
            tokenBalances.setTokenBalance(_tokenAddress,tokenBalances.getTokenBalance(_tokenAddress).sub(tokenCount));
        }
        else{
            uint256 need = tokenCount - tokenBalances.getTokenBalance(_tokenAddress);
            IAPContract(APContract).yieldsterExchange().delegatecall(abi.encodeWithSignature("exchangeToken(address,uint256)",_tokenAddress,need));
            _burn(msg.sender, _shares);
            IERC20(_tokenAddress).transfer(msg.sender,tokenCount);
            tokenBalances.setTokenBalance(_tokenAddress,tokenBalances.getTokenBalance(_tokenAddress).sub(tokenCount));
        }
    }

     /// @dev Function to Withdraw shares from the Vault.
    /// @param _shares Amount of Vault token shares.
    function withdraw(uint256 _shares)
        public
    {
        uint256 safeTotalSupply = totalSupply();
        _burn(msg.sender, _shares); 

        if(IAPContract(APContract).getVaultActiveStrategy(address(this)) != address(0)){
            uint256 safeStrategyBalance = IERC20(IAPContract(APContract).getVaultActiveStrategy(address(this))).balanceOf(address(this));
            if(safeStrategyBalance > 0){
                uint256 strategyShares = (_shares.mul(safeStrategyBalance)).div(safeTotalSupply); 
                IERC20(IAPContract(APContract).getVaultActiveStrategy(address(this))).transfer(msg.sender,strategyShares);
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
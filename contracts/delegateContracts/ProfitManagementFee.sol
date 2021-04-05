pragma solidity >=0.5.0 <0.7.0;
import "../storage/VaultStorage.sol";
contract ProfitManagementFee 
    is 
    VaultStorage 
{

    constructor()public ERC20Detailed(){

    }

  
  function executeSafeCleanUp() public returns(uint256){
    uint256 currentVaultNAV = getVaultNAV();
    uint256 tokensTobeMinted;
    if(currentVaultNAV<tokenBalances.getLastTransactionNav())
    {
    uint256 profit = tokenBalances.getLastTransactionNav()-currentVaultNAV;
    uint256 feeRate=20*100;
    uint256 fee=profit*feeRate/100;
    tokensTobeMinted = fee.div(tokenValueInUSD());
// Mint to benefeciary
    }
    tokenBalances.setLastTransactionNav(currentVaultNAV);
    return tokensTobeMinted;
  }
}

pragma solidity >=0.5.0 <0.7.0;
import "../storage/VaultStorage.sol";
contract ManagementFee 
    is 
    VaultStorage 
{
  
    function executeSafeCleanUp() 
        public
    {
        uint256 blockDifference = uint256(block.number).sub(tokenBalances.getLastTransactionBlockNumber());
        uint256 vaultNAV = getVaultNAV();
        if(vaultNAV > 0) {
            uint256 navIntrest = vaultNAV.mul(blockDifference.mul(1e18)).mul(uint256(2).mul(1e18)).div(uint256(262800000).mul(1e36));
            uint256 tokensTobeMinted = navIntrest.mul(1e18).div(tokenValueInUSD());
            _mint(IAPContract(APContract).yieldsterDAO(), tokensTobeMinted);
            tokenBalances.setTokenTobeMinted(tokenBalances.getTokenToBeMinted().add(tokensTobeMinted));
        }
    }
}

pragma solidity >=0.5.0 <0.7.0;
import "../storage/VaultStorage.sol";

contract ProfitManagementFee is VaultStorage {
    function executeSafeCleanUp() public {
        uint256 currentVaultNAV = getVaultNAV();
        if (currentVaultNAV > tokenBalances.getLastTransactionNav()) {
            uint256 profit = currentVaultNAV -
                tokenBalances.getLastTransactionNav();
            address[] memory strategies = IAPContract(APContract)
            .getVaultActiveStrategy(address(this));

            for (uint256 i = 0; i < strategies.length; i++) {
                (address benefeciary, uint256 percentage) = IAPContract(
                    APContract
                ).getStrategyManagementDetails(address(this), strategies[i]);
                uint256 fee = (profit.mul(percentage)).div(1e18);
                uint256 tokensTobeMinted = fee.div(tokenValueInUSD());
                _mint(benefeciary, tokensTobeMinted);
            }
        }
        tokenBalances.setLastTransactionNav(currentVaultNAV);
    }
}

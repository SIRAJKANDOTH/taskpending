pragma solidity >=0.5.0 <0.7.0;
import "../storage/VaultStorage.sol";
import "./storage/ManagementFeeStorage.sol";

contract ManagementFee is VaultStorage {
    function processPlatformFee(uint256 blockDifference, uint256 vaultNAV)
        internal
    {
        ManagementFeeStorage mStorage = ManagementFeeStorage(
            0xe40462adEf00dd036eF5B1C57862242B9205b658
        );
        uint256 platformFee = mStorage.getPlatformFee();
        uint256 platformNavInterest = vaultNAV
        .mul(blockDifference.mul(1e18))
        .mul(platformFee)
        .div(uint256(262800000).mul(1e36));
        uint256 platformShare = platformNavInterest.mul(1e18).div(
            tokenValueInUSD()
        );
        _mint(IAPContract(APContract).yieldsterDAO(), platformShare);
    }

    function processStrategyAnnualFee(uint256 blockDifference, uint256 vaultNAV)
        internal
    {
        ManagementFeeStorage mStorage = ManagementFeeStorage(
            0xe40462adEf00dd036eF5B1C57862242B9205b658
        );
        address[] memory strategies = IAPContract(APContract)
        .getVaultActiveStrategy(address(this));
        for (uint256 i = 0; i < strategies.length; i++) {
            (address benefeciary, ) = IAPContract(APContract)
            .getStrategyManagementDetails(address(this), strategies[i]);
            uint256 strategyFee = mStorage.getStrategyFee(strategies[i]);
            if (strategyFee > 0) {
                uint256 strategyAnnualNavInterest = vaultNAV
                .mul(blockDifference.mul(1e18))
                .mul(strategyFee)
                .div(uint256(262800000).mul(1e36));
                uint256 strategyShare = strategyAnnualNavInterest.mul(1e18).div(
                    tokenValueInUSD()
                );
                _mint(benefeciary, strategyShare);
            }
        }
    }

    function executeSafeCleanUp() public {
        uint256 blockDifference = uint256(block.number).sub(
            tokenBalances.getLastTransactionBlockNumber()
        );
        uint256 vaultNAV = getVaultNAV();

        if (vaultNAV > 0) {
            processPlatformFee(blockDifference, vaultNAV);
            processStrategyAnnualFee(blockDifference, vaultNAV);
            tokenBalances.setLastTransactionBlockNumber();
        }
    }
}

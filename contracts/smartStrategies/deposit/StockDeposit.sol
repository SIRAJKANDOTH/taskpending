// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
import "../../storage/VaultStorage.sol";

contract StockDeposit is VaultStorage {
    /// @dev Function to Deposit assets into the Vault.
    /// @param _tokenAddress Address of the deposit token.
    /// @param _amount Amount of deposit token.
    function deposit(address _tokenAddress, uint256 _amount) public {
        uint256 _share;
        IERC20 token = IERC20(_tokenAddress);
        if (totalSupply() == 0) {
            _share = IHexUtils(IAPContract(APContract).stringUtils())
                .toDecimals(_tokenAddress, _amount);
        } else {
            _share = getMintValue(getDepositNAV(_tokenAddress, _amount));
        }
        token.safeTransferFrom(msg.sender, address(this), _amount);
        tokenBalances.setTokenBalance(
            _tokenAddress,
            tokenBalances.getTokenBalance(_tokenAddress).add(_amount)
        );
        _mint(msg.sender, _share);
        addToAssetList(_tokenAddress);
    }
}

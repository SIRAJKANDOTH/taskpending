// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "./storage/VaultStorage.sol";

contract YieldsterVault is VaultStorage {
    /// @dev Function to upgrade the vault.
    function upgradeMasterCopy(address _mastercopy) external {
        _isYieldsterGOD();
        (bool result, ) = address(this).call(
            abi.encodeWithSignature("changeMasterCopy(address)", _mastercopy)
        );
        revertDelegate(result);
    }

    /// @dev Function to set APS Address.
    function setAPS(address _APContract) external {
        _isYieldsterGOD();
        APContract = _APContract;
    }

    /// @dev Function to toggle Emergency Break feature of the Vault.
    function toggleEmergencyBreak() external {
        _isYieldsterGOD();
        if (emergencyConditions == 1) emergencyConditions = 0;
        else if (emergencyConditions == 0) emergencyConditions = 1;
    }

    /// @dev Function to enable Emergency Exit feature of the Vault.
    function enableEmergencyExit() external {
        _isYieldsterGOD();
        emergencyConditions = 2;
        address[] memory vaultActiveStrategy = getVaultActiveStrategy();

        for (uint256 i = 0; i < vaultActiveStrategy.length; i++) {
            if (vaultActiveStrategy[i] != address(0)) {
                if (
                    IStrategy(vaultActiveStrategy[i]).balanceOf(address(this)) >
                    0
                ) {
                    (
                        ,
                        address withdrawToken,
                        uint256 withdrawAmount
                    ) = IStrategy(vaultActiveStrategy[i]).withdrawAllToSafe(
                            address(0)
                        );
                    IERC20(withdrawToken).safeTransfer(
                        IAPContract(APContract).emergencyVault(),
                        withdrawAmount
                    );
                }
                IStrategy(vaultActiveStrategy[i]).deRegisterSafe();
            }
        }
        for (uint256 i = 0; i < assetList.length; i++) {
            IERC20 token = IERC20(assetList[i]);
            uint256 tokenBalance = token.balanceOf(address(this));
            if (tokenBalance > 0) {
                token.safeTransfer(
                    IAPContract(APContract).emergencyVault(),
                    tokenBalance
                );
            }
        }
    }

    modifier onlyNormalMode() {
        _onlyNormalMode();
        _;
    }

    /// @dev Function that Disables vault interactions in case of Emergency Break and Emergency Exit.
    function _onlyNormalMode() private view {
        if (emergencyConditions == 1) {
            _isYieldsterGOD();
        } else if (emergencyConditions == 2) {
            revert("safe inactive");
        }
    }

    /// @dev Function that checks if the user is whitelisted.
    function _isWhiteListed() private view {
        if (whiteListGroups.length == 0) {
            return;
        } else {
            for (uint256 i = 0; i < whiteListGroups.length; i++) {
                if (
                    IWhitelist(IAPContract(APContract).whitelistModule())
                        .isMember(whiteListGroups[i], msg.sender)
                ) {
                    return;
                }
            }
            revert("Only Whitelisted");
        }
    }

    function _isYieldsterGOD() private view {
        require(
            msg.sender == IAPContract(APContract).yieldsterGOD(),
            "unauthorized"
        );
    }

    function _isStrategyManager() private view {
        require(msg.sender == vaultStrategyManager, "unauthorized");
    }

    // / @dev Setup function sets initial storage of contract.
    // / @param _vaultName Name of the Vault.
    // / @param _tokenName Name of the Vault Token.
    // / @param _symbol Symbol for the Vault Token.
    // / @param _vaultAPSManager Address of the Vault APS Manager.
    // / @param _vaultStrategyManager Address of the Vault Strategy Manager.
    // / @param _owner Address of the Vault owner.
    // / @param _whiteListGroups List of whitelist groups that is authorized to perform interactions.
    function setup(
        string calldata _tokenName,
        string calldata _symbol,
        address _vaultAPSManager,
        address _APContract,
        // address _vaultStrategyManager, //uncomment this line in production
        address _owner,
        uint256[] calldata _whiteListGroups
    ) external {
        require(!vaultSetupCompleted, "Vault is already setup");
        vaultSetupCompleted = true;
        vaultAPSManager = _vaultAPSManager;
        vaultStrategyManager = _vaultAPSManager;
        // APContract = 0xB24Ff34F5AE7F8Dde93A197FB406c1E78EEC0B25; //hardcode APContract address here before deploy to mainnet
        APContract = _APContract;
        owner = _owner;
        whiteListGroups = _whiteListGroups;
        setupToken(_tokenName, _symbol);
        tokenBalances = new TokenBalanceStorage();
    }

    /// @dev Function that is called once after vault creation to Register the Vault with APS.
    function registerVaultWithAPS() external onlyNormalMode {
        require(msg.sender == owner, "unauthorized");
        require(!vaultRegistrationCompleted, "Vault is already registered");
        vaultRegistrationCompleted = true;
        IAPContract(APContract).addVault(
            vaultAPSManager,
            vaultStrategyManager,
            whiteListGroups
        );
    }

    function setVaultSlippage(uint256 _slippage) external onlyNormalMode {
        _isStrategyManager();
        IAPContract(APContract).setVaultSlippage(_slippage);
    }

    /// @dev Function to manage the assets supported by the vaults.
    /// @param _enabledDepositAsset List of assets to be enabled in Deposit assets.
    /// @param _enabledWithdrawalAsset List of assets to be enabled in Withdrawal assets.
    /// @param _disabledDepositAsset List of assets to be disabled in Deposit assets.
    /// @param _disabledWithdrawalAsset List of assets to be disabled in Withdrawal assets.
    function setVaultAssets(
        address[] calldata _enabledDepositAsset,
        address[] calldata _enabledWithdrawalAsset,
        address[] calldata _disabledDepositAsset,
        address[] calldata _disabledWithdrawalAsset
    ) external onlyNormalMode {
        require(msg.sender == vaultAPSManager, "unauthorized");
        IAPContract(APContract).setVaultAssets(
            _enabledDepositAsset,
            _enabledWithdrawalAsset,
            _disabledDepositAsset,
            _disabledWithdrawalAsset
        );
    }

    /// @dev Function to manage the Strategy and corresponding protocols supported by the vaults.
    /// @param _vaultStrategy Address of the strategy to be enabled.
    /// @param _enabledStrategyProtocols List of protocols to be enabled in above strategy.
    /// @param _disabledStrategyProtocols List of protocols to be disabled in above strategy.
    /// @param _assetsToBeEnabled List of assets to be enabled in Vault for the strategy.
    function setVaultStrategyAndProtocol(
        address _vaultStrategy,
        address[] calldata _enabledStrategyProtocols,
        address[] calldata _disabledStrategyProtocols,
        address[] calldata _assetsToBeEnabled
    ) external onlyNormalMode {
        _isStrategyManager();
        IAPContract(APContract).setVaultStrategyAndProtocol(
            _vaultStrategy,
            _enabledStrategyProtocols,
            _disabledStrategyProtocols,
            _assetsToBeEnabled
        );
    }

    /// @dev Function to disable a strategy along with the assets.
    /// @param _strategyAddress Address of the strategy to be disabled.
    /// @param _assetsToBeDisabled List of assets to be disabled in Vault along with strategy.
    function disableVaultStrategy(
        address _strategyAddress,
        address[] calldata _assetsToBeDisabled
    ) external onlyNormalMode {
        _isStrategyManager();
        if (
            IAPContract(APContract).isStrategyActive(
                address(this),
                _strategyAddress
            )
        ) {
            if (IERC20(_strategyAddress).balanceOf(address(this)) > 0) {
                (
                    ,
                    address withdrawalAsset,
                    uint256 withdrawalAmount
                ) = IStrategy(_strategyAddress).withdrawAllToSafe(address(0));
                updateTokenBalance(withdrawalAsset, withdrawalAmount, true);
            }
            IStrategy(_strategyAddress).deRegisterSafe();
            IAPContract(APContract).deactivateVaultStrategy(_strategyAddress);
        }
        IAPContract(APContract).disableVaultStrategy(
            _strategyAddress,
            _assetsToBeDisabled
        );
    }

    /// @dev Function to activate a strategy in the vault.
    /// @param _activeVaultStrategy Address of the strategy to be activated.
    function setVaultActiveStrategy(address _activeVaultStrategy)
        external
        onlyNormalMode
    {
        _isStrategyManager();
        IAPContract(APContract).setVaultActiveStrategy(_activeVaultStrategy);
        IStrategy(_activeVaultStrategy).registerSafe();
    }

    /// @dev Function to deactivate a strategy in the vault.
    /// @param _strategyAddress Address of the strategy to be deactivated.
    function deactivateVaultStrategy(address _strategyAddress)
        external
        onlyNormalMode
    {
        _isStrategyManager();
        IAPContract(APContract).deactivateVaultStrategy(_strategyAddress);
        if (IERC20(_strategyAddress).balanceOf(address(this)) > 0) {
            (, address withdrawalAsset, uint256 withdrawalAmount) = IStrategy(
                _strategyAddress
            ).withdrawAllToSafe(address(0));
            updateTokenBalance(withdrawalAsset, withdrawalAmount, true);
        }
        IStrategy(_strategyAddress).deRegisterSafe();
    }

    /// @dev Function to set smart strategies to vault.
    /// @param _smartStrategyAddress Address of smart Strategy.
    /// @param _type Type of smart strategy.
    function setVaultSmartStrategy(address _smartStrategyAddress, uint256 _type)
        external
    {
        _isStrategyManager();
        IAPContract(APContract).setVaultSmartStrategy(
            _smartStrategyAddress,
            _type
        );
    }

    /// @dev Function to change the APS Manager of the Vault.
    /// @param _vaultAPSManager Address of the new APS Manager.
    function changeAPSManager(address _vaultAPSManager)
        external
        onlyNormalMode
    {
        require(
            IAPContract(APContract).yieldsterDAO() == msg.sender ||
                vaultAPSManager == msg.sender,
            "unauthorized"
        );
        vaultAPSManager = _vaultAPSManager;
        IAPContract(APContract).changeVaultAPSManager(_vaultAPSManager);
    }

    /// @dev Function to change the Strategy Manager of the Vault.
    /// @param _strategyManager Address of the new Strategy Manager.
    function changeStrategyManager(address _strategyManager)
        external
        onlyNormalMode
    {
        require(
            IAPContract(APContract).yieldsterDAO() == msg.sender ||
                vaultStrategyManager == msg.sender,
            "unauthorized"
        );
        vaultStrategyManager = _strategyManager;
        IAPContract(APContract).changeVaultStrategyManager(_strategyManager);
    }

    /// @dev Function to Deposit assets into the Vault.
    /// @param _tokenAddress Address of the deposit token.
    /// @param _amount Amount of deposit token.
    function deposit(address _tokenAddress, uint256 _amount)
        external
        onlyNormalMode
    {
        _isWhiteListed();
        require(
            IAPContract(APContract).isDepositAsset(_tokenAddress),
            "Not an approved deposit asset"
        );
        managementFeeCleanUp();
        (bool result, ) = IAPContract(APContract)
            .getDepositStrategy()
            .delegatecall(
                abi.encodeWithSignature(
                    "deposit(address,uint256)",
                    _tokenAddress,
                    _amount
                )
            );
        revertDelegate(result);
    }

    /// @dev Function to Withdraw assets from the Vault.
    /// @param _tokenAddress Address of the withdraw token.
    /// @param _shares Amount of Vault token shares.
    function withdraw(address _tokenAddress, uint256 _shares)
        external
        onlyNormalMode
    {
        _isWhiteListed();
        require(
            IAPContract(APContract).isWithdrawalAsset(_tokenAddress),
            "Not an approved Withdrawal asset"
        );
        require(
            balanceOf(msg.sender) >= _shares,
            "You don't have enough shares"
        );
        managementFeeCleanUp();
        (bool result, ) = IAPContract(APContract)
            .getWithdrawStrategy()
            .delegatecall(
                abi.encodeWithSignature(
                    "withdraw(address,uint256)",
                    _tokenAddress,
                    _shares
                )
            );
        revertDelegate(result);
    }

    // /// @dev Function to Withdraw shares from the Vault.
    // /// @param _shares Amount of Vault token shares.
    // function withdraw(uint256 _shares) external onlyNormalMode {
    //     _isWhiteListed();
    //     require(
    //         balanceOf(msg.sender) >= _shares,
    //         "You don't have enough shares"
    //     );
    //     managementFeeCleanUp();
    //     (bool result, ) = IAPContract(APContract)
    //     .getWithdrawStrategy()
    //     .delegatecall(abi.encodeWithSignature("withdraw(uint256)", _shares));
    //     revertDelegate(result);
    // }

    /// @dev Function to deposit vault assets to strategy
    /// @param _assets list of asset address to deposit
    /// @param _amount list of asset amounts to deposit
    function earn(
        address[] calldata _assets,
        uint256[] calldata _amount,
        bytes calldata data
    ) external onlyNormalMode {
        managementFeeCleanUp();
        address strategy = IAPContract(APContract).getStrategyFromMinter(
            msg.sender
        );
        require(
            IAPContract(APContract).isStrategyActive(address(this), strategy),
            "Strategy inactive"
        );
        for (uint256 i = 0; i < _assets.length; i++) {
            uint256 tokenBalance = tokenBalances.getTokenBalance(_assets[i]);
            if (tokenBalance >= _amount[i]) {
                updateTokenBalance(_assets[i], _amount[i], false);
                _approveToken(_assets[i], strategy, _amount[i]);
            }
        }
        IStrategy(strategy).deposit(_assets, _amount, data);
    }

    /// @dev Function to perform operation on Receivel of ERC1155 token from Yieldster Strategy Minter.
    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256,
        bytes calldata data
    ) external onlyNormalMode returns (bytes4) {
        managementFeeCleanUp();
        if (id == 0) {
            require(
                IAPContract(APContract).safeMinter() == msg.sender,
                "Only Safe Minter"
            );
            (bool success, ) = IAPContract(APContract).safeUtils().delegatecall(
                data
            );
            revertDelegate(success);
        } else if (id == 1) {
            require(
                IAPContract(APContract).isStrategyActive(
                    address(this),
                    IAPContract(APContract).getStrategyFromMinter(msg.sender)
                ),
                "Strategy inactive"
            );
            (bool success, bytes memory returnData) = IAPContract(APContract)
                .getStrategyFromMinter(msg.sender)
                .call(data);
            revertDelegate(success);
            updateBalance(returnData);
        } else if (id == 2) {
            require(
                IAPContract(APContract).getStrategyFromMinter(msg.sender) ==
                    IAPContract(APContract).getDepositStrategy(),
                "Not Deposit strategy"
            );
            (bool success, ) = IAPContract(APContract)
                .getStrategyFromMinter(msg.sender)
                .delegatecall(data);
            revertDelegate(success);
        } else if (id == 3) {
            require(
                IAPContract(APContract).getStrategyFromMinter(msg.sender) ==
                    IAPContract(APContract).getWithdrawStrategy(),
                "Not Withdraw strategy"
            );
            (bool success, ) = IAPContract(APContract)
                .getStrategyFromMinter(msg.sender)
                .delegatecall(data);
            revertDelegate(success);
        }
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    /// @dev Function to perform Management fee Calculations in the Vault.
    function managementFeeCleanUp() private {
        address[] memory managementFeeStrategies = IAPContract(APContract)
            .getVaultManagementFee();
        for (uint256 i = 0; i < managementFeeStrategies.length; i++) {
            managementFeeStrategies[i].delegatecall(
                abi.encodeWithSignature("executeSafeCleanUp()")
            );
        }
    }
}

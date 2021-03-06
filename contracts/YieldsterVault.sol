// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "./storage/VaultStorage.sol";

contract YieldsterVault
    is 
    VaultStorage
{
    /// @dev Function to upgrade the vault.
    function upgradeMasterCopy(address _mastercopy)
        external
    {
        require(msg.sender == IAPContract(APContract).yieldsterGOD(), "Sender not Authorized");
        (bool result, ) = address(this).call(abi.encodeWithSignature("changeMasterCopy(address)", _mastercopy));
        revertDelegate(result);
    }

    /// @dev Function to Enable Emergency Break feature of the Vault.
    function enableEmergencyBreak()
        external
    {
        require(msg.sender == IAPContract(APContract).yieldsterGOD(), "Sender not Authorized");
        emergencyConditions = 1;
    }

    /// @dev Function to disable the Emergency Break feature of the Vault.
    function disableEmergencyBreak()
        external
    {
        require(msg.sender == IAPContract(APContract).yieldsterGOD(), "Sender not Authorized");
        emergencyConditions = 0;
    }

    /// @dev Function to enable Emergency Exit feature of the Vault.
    function enableEmergencyExit()
        external
    {
        require(msg.sender == IAPContract(APContract).yieldsterGOD(), "Sender not Authorized");
        emergencyConditions = 2;
        address[] memory vaultActiveStrategy = getVaultActiveStrategy();

        for(uint256 i = 0; i < vaultActiveStrategy.length; i++ ){
            if(vaultActiveStrategy[i] != address(0)) {
                IStrategy(vaultActiveStrategy[i]).withdrawAllToSafe();
                IStrategy(vaultActiveStrategy[i]).deRegisterSafe();

            }
        }
        for(uint256 i = 0; i < assetList.length; i++ ){   
            IERC20 token = IERC20(assetList[i]);
            uint256 tokenBalance = token.balanceOf(address(this));
            if(tokenBalance > 0){
                token.transfer(IAPContract(APContract).emergencyVault(), tokenBalance);
            }
        }
    }

    modifier onlyNormalMode{
        _onlyNormalMode();
        _;
    }

    /// @dev Function that Disables vault interactions in case of Emergency Break and Emergency Exit.
    function _onlyNormalMode() private view {
        if(emergencyConditions == 1){
            require(msg.sender == IAPContract(APContract).yieldsterGOD(), "Sender not Authorized");
        }
        else if(emergencyConditions == 2){
            revert("This safe is no longer active");
        }
    }

    /// @dev Function that checks if the user is whitelisted.
    function isWhiteListed()
        private 
        view 
    {
        if(whiteListGroups.length == 0){
            return;
        }
        else{
            for (uint256 i = 0; i < whiteListGroups.length; i++){
                if (Whitelist(IAPContract(APContract).whitelistModule()).isMember(whiteListGroups[i], msg.sender)){
                    return;
                }
            }
            revert("Only Whitelisted");
        }
    }

    modifier onlyWhitelisted
    {
        isWhiteListed();
        _;
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _vaultName Name of the Vault.
    /// @param _tokenName Name of the Vault Token.
    /// @param _symbol Symbol for the Vault Token.
    /// @param _vaultAPSManager Address of the Vault APS Manager.
    /// @param _vaultStrategyManager Address of the Vault Strategy Manager.
    /// @param _APContract Address of the APS Contract.
    /// @param _whiteListGroups List of whitelist groups that is authorized to perform interactions.
    function setup(
        string calldata _vaultName,
        string calldata _tokenName,
        string calldata _symbol,
        address _vaultAPSManager,
        address _vaultStrategyManager,
        address _APContract, //Need to hardcode APContract address before deploying
        uint256[] calldata _whiteListGroups
    )
        external
    {
        require(!vaultSetupCompleted, "Vault is already setup");
        vaultSetupCompleted = true;
        vaultName = _vaultName;
        vaultAPSManager = _vaultAPSManager;
        vaultStrategyManager = _vaultStrategyManager;
        APContract = _APContract; //hardcode APContract address here before deploy to mainnet
        owner = tx.origin;
        whiteListGroups = _whiteListGroups;
        setupToken(_tokenName, _symbol);
        tokenBalances = new TokenBalanceStorage();
    }

    /// @dev Function that is called once after vault creation to Register the Vault with APS.
    function registerVaultWithAPS()
        onlyNormalMode
        external
    {
        require(msg.sender == owner, "Only owner can perform this operation");
        require(!vaultRegistrationCompleted, "Vault is already registered");
        vaultRegistrationCompleted = true;
        IAPContract(APContract).addVault(vaultAPSManager, vaultStrategyManager, whiteListGroups, owner);
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
    )
    onlyNormalMode
    external
    {
        require(msg.sender == vaultAPSManager || msg.sender == owner, "Sender not Authorized");
        managementFeeCleanUp();
        IAPContract(APContract).setVaultAssets(_enabledDepositAsset, _enabledWithdrawalAsset, _disabledDepositAsset, _disabledWithdrawalAsset);
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
    )
    onlyNormalMode
    external
    {
        require(msg.sender == vaultStrategyManager || msg.sender == owner, "Sender not Authorized");
        IAPContract(APContract).setVaultStrategyAndProtocol(_vaultStrategy, _enabledStrategyProtocols, _disabledStrategyProtocols, _assetsToBeEnabled);
    }

    /// @dev Function to disable a strategy along with the assets.
    /// @param _strategyAddress Address of the strategy to be disabled.
    /// @param _assetsToBeDisabled List of assets to be disabled in Vault along with strategy.
    function disableVaultStrategy(address _strategyAddress, address[] calldata _assetsToBeDisabled)
        onlyNormalMode
        external
    {
        require(msg.sender == vaultStrategyManager || msg.sender == owner, "Sender not Authorized");
        if(IAPContract(APContract).isStrategyActive(address(this), _strategyAddress)){
            if(IERC20(_strategyAddress).balanceOf(address(this)) > 0){
                IStrategy(_strategyAddress).withdrawAllToSafe();
            }
            IStrategy(_strategyAddress).deRegisterSafe();
            IAPContract(APContract).deactivateVaultStrategy(_strategyAddress);
        }
        IAPContract(APContract).disableVaultStrategy(_strategyAddress, _assetsToBeDisabled);
    }

    /// @dev Function to activate a strategy in the vault.
    /// @param _activeVaultStrategy Address of the strategy to be activated.
    function setVaultActiveStrategy(address _activeVaultStrategy)
        onlyNormalMode
        external
    {
        require(msg.sender == vaultStrategyManager || msg.sender == owner, "Sender not Authorized");
        require(IAPContract(APContract)._isStrategyEnabled(address(this), _activeVaultStrategy) ,"This strategy is not enabled");
        IAPContract(APContract).setVaultActiveStrategy(_activeVaultStrategy);
        IStrategy(_activeVaultStrategy).registerSafe();        
    }


    /// @dev Function to deactivate a strategy in the vault.
    /// @param _strategyAddress Address of the strategy to be deactivated.
    function deactivateVaultStrategy(address _strategyAddress)
        onlyNormalMode
        external
    {
        require(msg.sender == vaultStrategyManager || msg.sender == owner, "Sender not Authorized");
        require(IAPContract(APContract)._isStrategyEnabled(address(this), _strategyAddress) ,"This strategy is not enabled");
        require(IAPContract(APContract).isStrategyActive(address(this), _strategyAddress), "This strategy is not active right now");
        if(IERC20(_strategyAddress).balanceOf(address(this)) > 0){
            IStrategy(_strategyAddress).withdrawAllToSafe();
        }
        IStrategy(_strategyAddress).deRegisterSafe();
        IAPContract(APContract).deactivateVaultStrategy(_strategyAddress);        
    }

    /// @dev Function to get the address of active strategy in the vault.
    function getVaultActiveStrategy()
        public
        view
        returns(address[] memory)
    {
        return IAPContract(APContract).getVaultActiveStrategy(address(this));
    }

    /// @dev Function to set smart strategies to vault.
    /// @param _smartStrategyAddress Address of smart Strategy.
    /// @param _type Type of smart strategy.
    function setVaultSmartStrategy(address _smartStrategyAddress, uint256 _type)
        external
    {
        require(msg.sender == vaultStrategyManager || msg.sender == owner, "Sender not Authorized");
        IAPContract(APContract).setVaultSmartStrategy(_smartStrategyAddress, _type);
    }


    /// @dev Function to change the APS Manager of the Vault.
    /// @param _vaultAPSManager Address of the new APS Manager.
    function changeAPSManager(address _vaultAPSManager)
        onlyNormalMode
        external
    {
        require(IAPContract(APContract).yieldsterDAO() == msg.sender || vaultAPSManager == msg.sender, "Sender not Authorized");
        vaultAPSManager = _vaultAPSManager;
        IAPContract(APContract).changeVaultAPSManager(_vaultAPSManager);
    }


    /// @dev Function to change the Strategy Manager of the Vault.
    /// @param _strategyManager Address of the new Strategy Manager.
    function changeStrategyManager(address _strategyManager)
        onlyNormalMode
        external
    {
        require(IAPContract(APContract).yieldsterDAO() == msg.sender || vaultStrategyManager == msg.sender, "Sender not Authorized");
        vaultStrategyManager = _strategyManager;
        IAPContract(APContract).changeVaultStrategyManager(_strategyManager);
    }

    /// @dev Function to Deposit assets into the Vault.
    /// @param _tokenAddress Address of the deposit token.
    /// @param _amount Amount of deposit token.
    function deposit(address _tokenAddress, uint256 _amount)
        onlyNormalMode
        onlyWhitelisted
        external
    { 
        require(IAPContract(APContract).isDepositAsset(_tokenAddress), "Not an approved deposit asset");
        managementFeeCleanUp();
        (bool result, ) = IAPContract(APContract).getDepositStrategy().delegatecall(abi.encodeWithSignature("deposit(address,uint256)", _tokenAddress, _amount));
        revertDelegate(result);
    }

    /// @dev Function to Withdraw assets from the Vault.
    /// @param _tokenAddress Address of the withdraw token.
    /// @param _shares Amount of Vault token shares.
    function withdraw(address _tokenAddress, uint256 _shares)
        onlyNormalMode
        onlyWhitelisted
        external
    {
        require(IAPContract(APContract).isWithdrawalAsset(_tokenAddress),"Not an approved Withdrawal asset");
        require(balanceOf(msg.sender) >= _shares,"You don't have enough shares");
        managementFeeCleanUp();
        (bool result, ) = IAPContract(APContract).getWithdrawStrategy().delegatecall(abi.encodeWithSignature("withdraw(address,uint256)", _tokenAddress, _shares));
        revertDelegate(result);

    }

    /// @dev Function to Withdraw shares from the Vault.
    /// @param _shares Amount of Vault token shares.
    function withdraw(uint256 _shares)
        onlyNormalMode
        onlyWhitelisted
        external
    {
        require(balanceOf(msg.sender) >= _shares,"You don't have enough shares");
        managementFeeCleanUp();
        (bool result, ) = IAPContract(APContract).getWithdrawStrategy().delegatecall(abi.encodeWithSignature("withdraw(uint256)", _shares));
        revertDelegate(result);
    }

    /// @dev Function to deposit vault assets to strategy
    /// @param _assets list of asset address to deposit
    /// @param _amount list of asset amounts to deposit
    function earn(address[] memory _assets, uint256[] memory _amount) 
        onlyNormalMode
        public
    {
        address strategy = IAPContract(APContract).getStrategyFromMinter(msg.sender);
        require(IAPContract(APContract).isStrategyActive(address(this), strategy), "Strategy inactive");
        for(uint256 i = 0; i < _assets.length; i++) {
            uint256 tokenBalance = tokenBalances.getTokenBalance(_assets[i]);
            if(tokenBalance > _amount[i]) { 
                IERC20(_assets[i]).approve(strategy, _amount[i]);
                IStrategy(strategy).deposit(_assets[i], _amount[i]);
            }
        }
    }


    /// @dev Function to perform operation on Receivel of ERC1155 token from Yieldster Strategy Minter.
    function onERC1155Received(
        address ,
        address ,
        uint256 id,
        uint256 ,
        bytes calldata data
    )
    external
    onlyNormalMode
    returns(bytes4)
    {
        IHexUtils hexUtils = IHexUtils(IAPContract(APContract).stringUtils());
        if(id == 0) {
            require(IAPContract(APContract).safeMinter() == msg.sender, "Only Safe Minter");
            (bool success,) = IAPContract(APContract).safeUtils().delegatecall(hexUtils.fromHex(data));
            revertDelegate(success);
        }
        else if(id == 1){
            require(IAPContract(APContract).isStrategyActive(address(this),IAPContract(APContract).getStrategyFromMinter(msg.sender)), "Strategy inactive");
            (bool success,) = IAPContract(APContract).getStrategyFromMinter(msg.sender).call(hexUtils.fromHex(data));
            revertDelegate(success);
        } 
        else if(id == 2){
            require(IAPContract(APContract).getStrategyFromMinter(msg.sender) == IAPContract(APContract).getDepositStrategy(), "Not Deposit strategy");
            (bool success,) = IAPContract(APContract).getStrategyFromMinter(msg.sender).delegatecall(hexUtils.fromHex(data));
            revertDelegate(success);
        }   
        else if(id == 3){
            require(IAPContract(APContract).getStrategyFromMinter(msg.sender) == IAPContract(APContract).getWithdrawStrategy(), "Not Withdraw strategy");
            (bool success,) = IAPContract(APContract).getStrategyFromMinter(msg.sender).delegatecall(hexUtils.fromHex(data));
            revertDelegate(success);
        }   
    }

    function onERC1155BatchReceived(
        address ,
        address ,
        uint256[] calldata ,
        uint256[] calldata ,
        bytes calldata 
    )
    external
    returns(bytes4)
    {
        return 0;
    }

    /// @dev Function to perform Management fee Calculations in the Vault.
    function managementFeeCleanUp() 
        private
    {
        address[] memory managementFeeStrategies = IAPContract(APContract).getVaultManagementFee();
        for (uint256 i = 0; i < managementFeeStrategies.length; i++){
            managementFeeStrategies[i].delegatecall(abi.encodeWithSignature("executeSafeCleanUp()"));
        }
    }
}

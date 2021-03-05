// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "./storage/VaultStorage.sol";

contract GnosisSafe
    is 
    VaultStorage
{
    /// @dev Function to Enable Emergency Break feature of the Vault.
    function enableEmergencyBreak()
        public
    {
        require(msg.sender == IAPContract(APContract).yieldsterGOD(), "Sender not Authorized");
        emergencyBreak = true;
    }

    /// @dev Function to disable the Emergency Break feature of the Vault.
    function disableEmergencyBreak()
        public
    {
        require(msg.sender == IAPContract(APContract).yieldsterGOD(), "Sender not Authorized");
        emergencyBreak = false;
    }

    /// @dev Function to enable Emergency Exit feature of the Vault.
    function enableEmergencyExit()
        public
    {
        require(msg.sender == IAPContract(APContract).yieldsterGOD(), "Sender not Authorized");
        emergencyExit = true;
        address vaultActiveStrategy = getVaultActiveStrategy();

        if(vaultActiveStrategy != address(0)){
            IStrategy(getVaultActiveStrategy()).withdrawAllToSafe();
            IStrategy(getVaultActiveStrategy()).deRegisterSafe();
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
        if(emergencyBreak)
        {
            require(msg.sender == IAPContract(APContract).yieldsterGOD(), "Sender not Authorized");
        }
        else if(emergencyExit){
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
                if (whiteList.isMember(whiteListGroups[i], msg.sender)){
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
        string memory _vaultName,
        string memory _tokenName,
        string memory _symbol,
        address _vaultAPSManager,
        address _vaultStrategyManager,
        address _APContract, //Need to hardcode APContract address before deploying
        uint256[] memory _whiteListGroups
    )
        public
    {
        require(!vaultSetupCompleted, "Vault is already setup");
        vaultSetupCompleted = true;
        vaultName = _vaultName;
        vaultAPSManager = _vaultAPSManager;
        vaultStrategyManager = _vaultStrategyManager;
        APContract = _APContract; //hardcode APContract address here before deploy to mainnet
        owner = tx.origin;
        whiteListGroups = _whiteListGroups;
        whiteList = Whitelist(IAPContract(APContract).whitelistModule());
        oneInch = 0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;
        setupToken(_tokenName, _symbol);
        tokenBalances=new TokenBalanceStorage();
    }

    /// @dev Function that is called once after vault creation to Register the Vault with APS.
    function registerVaultWithAPS()
        onlyNormalMode
        public
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
        address[] memory _enabledDepositAsset,
        address[] memory _enabledWithdrawalAsset,
        address[] memory _disabledDepositAsset,
        address[] memory _disabledWithdrawalAsset
    )
    onlyNormalMode
    public
    {
        require(msg.sender == vaultAPSManager, "Sender not Authorized");
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
        address[] memory _enabledStrategyProtocols,
        address[] memory _disabledStrategyProtocols,
        address[] memory _assetsToBeEnabled
    )
    onlyNormalMode
    public
    {
        require(msg.sender == vaultStrategyManager, "Sender not Authorized");
        IAPContract(APContract).setVaultStrategyAndProtocol(_vaultStrategy, _enabledStrategyProtocols, _disabledStrategyProtocols, _assetsToBeEnabled);
    }

    /// @dev Function to disable a strategy along with the assets.
    /// @param _strategyAddress Address of the strategy to be disabled.
    /// @param _assetsToBeDisabled List of assets to be disabled in Vault along with strategy.
    function disableVaultStrategy(address _strategyAddress, address[] memory _assetsToBeDisabled)
        onlyNormalMode
        public
    {
        require(msg.sender == vaultStrategyManager, "Sender not Authorized");
        if(getVaultActiveStrategy() == _strategyAddress){
            if(IERC20(_strategyAddress).balanceOf(address(this)) > 0){
                IStrategy(getVaultActiveStrategy()).withdrawAllToSafe();
            }
            IStrategy(getVaultActiveStrategy()).deRegisterSafe();
            IAPContract(APContract).deactivateVaultStrategy(_strategyAddress);
        }
        IAPContract(APContract).disableVaultStrategy(_strategyAddress, _assetsToBeDisabled);
    }

    /// @dev Function to activate a strategy in the vault.
    /// @param _activeVaultStrategy Address of the strategy to be activated.
    function setVaultActiveStrategy(address _activeVaultStrategy)
        onlyNormalMode
        public
    {
        require(msg.sender == vaultStrategyManager, "Sender not Authorized");
        require(IAPContract(APContract)._isStrategyEnabled(address(this), _activeVaultStrategy) ,"This strategy is not enabled");
        if(getVaultActiveStrategy() != address(0)){
            if(IERC20(getVaultActiveStrategy()).balanceOf(address(this)) > 0){
                IStrategy(getVaultActiveStrategy()).withdrawAllToSafe();
            }
            IStrategy(getVaultActiveStrategy()).deRegisterSafe();
        }
        IAPContract(APContract).setVaultActiveStrategy(_activeVaultStrategy);
        IStrategy(_activeVaultStrategy).registerSafe();        
    }


    /// @dev Function to deactivate a strategy in the vault.
    /// @param _strategyAddress Address of the strategy to be deactivated.
    function deactivateVaultStrategy(address _strategyAddress)
        onlyNormalMode
        public
    {
        require(msg.sender == vaultStrategyManager, "Sender not Authorized");
        require(IAPContract(APContract)._isStrategyEnabled(address(this), _strategyAddress) ,"This strategy is not enabled");
        require(getVaultActiveStrategy() == _strategyAddress, "This strategy is not active right now");
        if(IERC20(_strategyAddress).balanceOf(address(this)) > 0){
            IStrategy(getVaultActiveStrategy()).withdrawAllToSafe();
        }
        IStrategy(getVaultActiveStrategy()).deRegisterSafe();
        IAPContract(APContract).deactivateVaultStrategy(_strategyAddress);        
    }

    /// @dev Function to get the address of active strategy in the vault.
    function getVaultActiveStrategy()
        public
        view
        returns(address)
    {
        return IAPContract(APContract).getVaultActiveStrategy(address(this));
    }

    

    /// @dev Function to change the APS Manager of the Vault.
    /// @param _vaultAPSManager Address of the new APS Manager.
    function changeAPSManager(address _vaultAPSManager)
        onlyNormalMode
        public
    {
        require(IAPContract(APContract).yieldsterDAO() == msg.sender || vaultAPSManager == msg.sender, "Sender not Authorized");
        IAPContract(APContract).changeVaultAPSManager(_vaultAPSManager);
        vaultAPSManager = _vaultAPSManager;
    }


    /// @dev Function to change the Strategy Manager of the Vault.
    /// @param _strategyManager Address of the new Strategy Manager.
    function changeStrategyManager(address _strategyManager)
        onlyNormalMode
        public
    {
        require(IAPContract(APContract).yieldsterDAO() == msg.sender || vaultStrategyManager == msg.sender, "Sender not Authorized");
        IAPContract(APContract).changeVaultAPSManager(_strategyManager);
        vaultStrategyManager = _strategyManager;
    }

    /// @dev Function to get the amount of Vault Tokens to be minted for the deposit NAV.
    /// @param depositNAV NAV of the Deposit Amount.
    function getMintValue(uint256 depositNAV)
        internal
        view
        returns (uint256)
    {
        return (depositNAV.mul(totalSupply())).div( getVaultNAV());
    }

    /// @dev Function to Deposit assets into the Vault.
    /// @param _tokenAddress Address of the deposit token.
    /// @param _amount Amount of deposit token.
    function deposit(address _tokenAddress, uint256 _amount)
        onlyNormalMode
        onlyWhitelisted
        public
    { 
        uint256 _share;
        require(IAPContract(APContract).isDepositAsset(_tokenAddress), "Not an approved deposit asset");
        IERC20 token = ERC20(_tokenAddress);

        if(totalSupply() == 0){
            _share = _amount;
        }
        else{
            _share = getMintValue(getDepositNAV(_tokenAddress, _amount));
        }

        token.transferFrom(msg.sender, address(this), _amount);
        tokenBalances.setTokenBalance(_tokenAddress,tokenBalances.getTokenBalance(_tokenAddress).add(_amount));
        _mint(msg.sender, _share);

        if(!isAssetDeposited[_tokenAddress]){
            isAssetDeposited[_tokenAddress] = true;
            assetList.push(_tokenAddress);
        }
         
    }

    /// @dev Function to Withdraw assets from the Vault.
    /// @param _tokenAddress Address of the withdraw token.
    /// @param _shares Amount of Vault token shares.
    function withdraw(address _tokenAddress, uint256 _shares)
        onlyNormalMode
        onlyWhitelisted
        public
    {
        require(IAPContract(APContract).isWithdrawalAsset(_tokenAddress),"Not an approved Withdrawal asset");
        require(balanceOf(msg.sender) >= _shares,"You don't have enough shares");
        managementFeeCleanUp();
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
            exchangeToken(_tokenAddress, need);
            _burn(msg.sender, _shares);
            IERC20(_tokenAddress).transfer(msg.sender,tokenCount);
            tokenBalances.setTokenBalance(_tokenAddress,tokenBalances.getTokenBalance(_tokenAddress).sub(tokenCount));
        }
    }

    /// @dev Function to exchange tokens to for a target token.
    /// @param _targetToken Address of the target token.
    /// @param _amount Amount of target tokens required.
    function exchangeToken(address _targetToken, uint256 _amount)
        internal
    {
        for(uint256 i = 0; i < assetList.length; i++ ){
            IERC20 haveToken = IERC20(assetList[i]);
            uint256 targetTokenUSD = IAPContract(APContract).getUSDPrice(_targetToken);
            uint256 haveTokenUSD = IAPContract(APContract).getUSDPrice(assetList[i]);

            if((haveToken.balanceOf(address(this)).mul(uint256(haveTokenUSD))).div(1e18) > (_amount.mul(uint256(targetTokenUSD))).div(1e18)){
                (uint256 returnAmount, uint256[] memory distribution) = 
                IExchange(oneInch).getExpectedReturn(assetList[i], _targetToken, _amount, 0, 0);
                uint256 adjustedAmount = _amount + (_amount - returnAmount).mul(3);

                if( (haveToken.balanceOf(address(this)).mul(uint256(haveTokenUSD))).div(1e18) > (adjustedAmount.mul(uint256(targetTokenUSD))).div(1e18)){
                    IExchange(oneInch).swap(assetList[i], _targetToken, adjustedAmount, _amount, distribution, 0);
                    break;
                }
            }                
        }
    }

    /// @dev Function to Withdraw shares from the Vault.
    /// @param _shares Amount of Vault token shares.
    function withdraw(uint256 _shares)
        onlyNormalMode
        onlyWhitelisted
        public
    {
        require(balanceOf(msg.sender) >= _shares,"You don't have enough shares");
        managementFeeCleanUp();
        uint256 safeTotalSupply = totalSupply();
        _burn(msg.sender, _shares); 

        if(getVaultActiveStrategy() != address(0)){
            uint256 safeStrategyBalance = IERC20(getVaultActiveStrategy()).balanceOf(address(this));
            if(safeStrategyBalance > 0){
                uint256 strategyShares = (_shares.mul(safeStrategyBalance)).div(safeTotalSupply); 
                IERC20(getVaultActiveStrategy()).transfer(msg.sender,strategyShares);
            }
        }

        for(uint256 i = 0; i < assetList.length; i++ ){   
            IERC20 token = IERC20(assetList[i]);
            if(token.balanceOf(address(this)) > 0){
                uint256 tokensToGive = (_shares.mul(token.balanceOf(address(this)))).div(safeTotalSupply);
                token.transfer(msg.sender, tokensToGive);
            }
        }
    }

    /// @dev Function to invest in the Active Vault strategy.
    /// @param _amount Amount of strategy want tokens to be invested.
    function earn(uint256 _amount) 
        onlyNormalMode
        public
    {
        address _strategy = IAPContract(APContract).getVaultActiveStrategy(address(this));
        uint256 _balance = tokenBalances.getTokenBalance(IStrategy(_strategy).want());
        if(_amount <= _balance){
            IERC20(IStrategy(_strategy).want()).approve(_strategy, _amount);
            IStrategy(_strategy).deposit(_amount);
            tokenBalances.setTokenBalance(IStrategy(_strategy).want(),_balance.sub(_amount));
        }
        else{
            exchangeToken(IStrategy(_strategy).want(),_amount);
            IERC20(IStrategy(_strategy).want()).approve(_strategy, _amount);
            IStrategy(_strategy).deposit(_amount);
            tokenBalances.setTokenBalance(IStrategy(_strategy).want(),tokenBalances.getTokenBalance(IStrategy(_strategy).want()).sub(_amount));
        }
    }

    /// @dev Function to cleanup vault unsupported tokens to the Yieldster Treasury.
    /// @param cleanUpList List of unsupported tokens to be transfered.
    function safeCleanUp(address[] memory cleanUpList)
        public
    {
        require(IAPContract(APContract).strategyMinter() == msg.sender, "Only Yieldster Strategy Minter");
        for (uint256 i = 0; i < cleanUpList.length; i++){
            if(! (IAPContract(APContract)._isVaultAsset(cleanUpList[i]))){
                uint256 _amount = IERC20(cleanUpList[i]).balanceOf(address(this));
                if(_amount > 0){
                    IERC20(cleanUpList[i]).transfer(IAPContract(APContract).yieldsterTreasury(), _amount);
                }
            }
        }
    }

    /// @dev Function to perform operation on Receivel of ERC1155 token from Yieldster Strategy Minter.
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
    external
    onlyNormalMode
    returns(bytes4)
    {
        require(IAPContract(APContract).strategyMinter() == msg.sender, "Only Yieldster Strategy Minter");
        HexUtils hexUtils = new HexUtils();
        if(id == 0){
            (bool success, bytes memory result) = address(this).call(hexUtils.fromHex(data));
            if(!success){
                revert("transaction failed");
            }
        }
        else if(id == 1){
            (bool success, bytes memory result) = IAPContract(APContract).getVaultActiveStrategy(address(this)).call(hexUtils.fromHex(data));
            if(!success){
                revert("transaction failed");
            }
        }   
        else{
            address smartStrategy = IAPContract(APContract).getStrategyInstructionId(id);
            (bool success, bytes memory result) = address(smartStrategy).delegatecall(hexUtils.fromHex(data));
            if(!success){
                revert("transaction failed");
            }
        }
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
    external
    onlyNormalMode
    returns(bytes4)
    {
        require(IAPContract(APContract).strategyMinter() == msg.sender, "Only Yieldster Strategy Minter");
        _mint(tx.origin, 100);
        return "";
    }
    
    event testManagementFee(uint256, string);

    /// @dev Function to perform Management fee Calculations in the Vault.
    /// @param delegateContract Address of the Management Fee strategy contract.
    function managementFeeCleanUp(address delegateContract) 
        private
    {
        (bool success2, bytes memory result) = delegateContract.delegatecall(abi.encodeWithSignature("executeSafeCleanUp()"));
    }
}

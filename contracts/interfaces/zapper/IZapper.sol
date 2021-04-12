pragma solidity >=0.5.0 <0.7.0;

interface IZapper{
     /**
    @notice This function is used to add liquidity to yVaults
    @param _toWhomToIssue recipient address
    @param _toYVaultAddress The address of vault to add liquidity to
    @param _vaultType Type of underlying token: 0 token; 1 aToken; 2 LP token
    @param _fromTokenAddress The token used for investment (address(0x00) if ether)
    @param _amount The amount of ERC to invest
    @param _minYTokens for slippage
    @return yTokensRec
    */
    function ZapIn(
        address _toWhomToIssue,
        address _toYVaultAddress,
        uint16 _vaultType,
        address _fromTokenAddress,
        uint256 _amount,
        uint256 _minYTokens
    ) external payable returns (uint256);

     /**
    @notice This function is used to remove liquidity from yVaults
    @param _toWhomToIssue recipient address
    @param _ToTokenContractAddress The address of the token to withdraw
    @param _fromYVaultAddress The address of the vault to exit
    @param _vaultType Type of underlying token: 0 token; 1 aToken; 2 LP token
    @param _IncomingAmt The amount of vault tokens removed
    @param _minTokensRec for slippage
    @return toTokensReceived
     */
    function ZapOut(
        address payable _toWhomToIssue,
        address _ToTokenContractAddress,
        address _fromYVaultAddress,
        uint16 _vaultType,
        uint256 _IncomingAmt,
        uint256 _minTokensRec
    ) external returns (uint256);

    /**
    @notice This function adds liquidity to a Yearn Curve vaults with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param toToken Intermediate token to swap to
    @param toVault Yearn vault address
    @param minYVTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
    @param _swapTarget Excecution target for the swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @return tokensReceived- Quantity of Vault tokens received
     */
    function ZapInCurveVault(
        address fromToken,
        uint256 amountIn,
        address toToken,
        address toVault,
        uint256 minYVTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable returns (uint256);


    /**
    @notice This function adds liquidity to a Yearn vaults with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param toVault Yearn vault address
    @param isAaveUnderlying True is vault contains aave token
    @param minYVTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
    @param _swapTarget Excecution target for the swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @return tokensReceived- Quantity of Vault tokens received
     */
    function ZapInTokenVault(
        address fromToken,
        uint256 amountIn,
        address toVault,
        bool isAaveUnderlying,
        uint256 minYVTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable  returns (uint256);

}
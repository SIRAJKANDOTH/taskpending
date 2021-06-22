pragma solidity >=0.5.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/yearn/IVault.sol";
import "../interfaces/IExchange.sol";

contract ReentrancyGuard {
    bool private _notEntered;

    constructor() internal {
        _notEntered = true;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;

        _;

        _notEntered = true;
    }
}

contract Zapper is ReentrancyGuard {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public stopped = false;
    address public oneInch;

    event Zapin(
        address _toWhomToIssue,
        address _toYVaultAddress,
        uint256 _Outgoing
    );

    event Zapout(
        address _toWhomToIssue,
        address _fromYVaultAddress,
        address _toTokenAddress,
        uint256 _tokensRecieved
    );

    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    constructor(address _oneInch) public {
        oneInch = _oneInch;
    }

    function swap(
        address fromToken,
        address toToken,
        uint256 amount
    ) internal returns (uint256) {
        (uint256 returnAmount, uint256[] memory distribution) =
            IExchange(oneInch).getExpectedReturn(
                fromToken,
                toToken,
                amount,
                0,
                0
            );
        IERC20(fromToken).safeApprove(oneInch, amount);
        uint256 returnedTokenCount =
            IExchange(oneInch).swap(
                fromToken,
                toToken,
                amount,
                returnAmount,
                distribution,
                0
            );

        return returnedTokenCount;
    }

    function _vaultDeposit(
        address underlyingVaultToken,
        uint256 amount,
        address toVault,
        uint256 minTokensRec
    ) internal returns (uint256 tokensReceived) {
        IERC20(underlyingVaultToken).safeApprove(toVault, amount);
        uint256 iniYVaultBal = IERC20(toVault).balanceOf(address(this));
        IVault(toVault).deposit(amount);
        tokensReceived = IERC20(toVault).balanceOf(address(this)).sub(
            iniYVaultBal
        );

        require(tokensReceived >= minTokensRec, "Err: High Slippage");

        IERC20(toVault).safeTransfer(msg.sender, tokensReceived);
    }

    function ZapInCurveVault(
        address fromToken,
        uint256 amountIn,
        address toToken,
        address toVault,
        uint256 minYVTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate
    )
        external
        payable
        nonReentrant
        stopInEmergency
        returns (uint256 tokensReceived)
    {
        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), amountIn);
        address acceptingToken = IVault(toVault).token();
        if (fromToken != acceptingToken) {
            uint256 swapReturn = swap(fromToken, acceptingToken, amountIn);
            tokensReceived = _vaultDeposit(
                acceptingToken,
                swapReturn,
                toVault,
                minYVTokens
            );
        } else {
            tokensReceived = _vaultDeposit(
                acceptingToken,
                amountIn,
                toVault,
                minYVTokens
            );
        }
    }

    function ZapOut(
        address payable _toWhomToIssue,
        address _ToTokenContractAddress,
        address _fromYVaultAddress,
        uint16 _vaultType,
        uint256 _IncomingAmt,
        uint256 _minTokensRec
    ) public nonReentrant stopInEmergency returns (uint256) {
        IVault vaultToExit = IVault(_fromYVaultAddress);
        address underlyingVaultToken = vaultToExit.token();

        IERC20(address(vaultToExit)).safeTransferFrom(
            msg.sender,
            address(this),
            _IncomingAmt
        );

        vaultToExit.withdraw(_IncomingAmt);
        uint256 underlyingReceived =
            IERC20(underlyingVaultToken).balanceOf(address(this));

        uint256 toTokensReceived;
        if (_ToTokenContractAddress == underlyingVaultToken) {
            IERC20(underlyingVaultToken).safeTransfer(
                _toWhomToIssue,
                underlyingReceived
            );
            toTokensReceived = underlyingReceived;
        } else {
            toTokensReceived = swap(
                underlyingVaultToken,
                _ToTokenContractAddress,
                underlyingReceived
            );
            IERC20(_ToTokenContractAddress).safeTransfer(
                _toWhomToIssue,
                toTokensReceived
            );
        }

        require(toTokensReceived >= _minTokensRec, "High Slippage");

        emit Zapout(
            _toWhomToIssue,
            _fromYVaultAddress,
            _ToTokenContractAddress,
            toTokensReceived
        );

        return toTokensReceived;
    }
}

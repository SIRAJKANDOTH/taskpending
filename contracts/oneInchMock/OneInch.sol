pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IHexUtils.sol";
import "../interfaces/IPriceModule.sol";

contract OneInch {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IPriceModule private priceModule;
    IHexUtils private hexUtils;

    constructor(address _hexUtils, address _priceModule) public {
        priceModule = IPriceModule(_priceModule);
        hexUtils = IHexUtils(_hexUtils);
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    ) public payable returns (uint256) {
        require(address(fromToken) != address(0));
        require(address(destToken) != address(0));
        require(amount > 0);
        uint256 fromNav =
            (
                priceModule.getUSDPrice(address(fromToken)).mul(
                    hexUtils.toDecimals(address(fromToken), amount)
                )
            )
                .div(1e18);
        uint256 destTokenCount =
            hexUtils.fromDecimals(
                address(destToken),
                (fromNav.mul(1e18)).div(
                    priceModule.getUSDPrice(address(destToken))
                )
            );
        uint256 haveTokens;
        if (destToken.balanceOf(address(this)) >= destTokenCount) {
            haveTokens = destTokenCount;
        } else {
            haveTokens = destToken.balanceOf(address(this));
        }
        if (haveTokens < minReturn) revert("Not Enough Tokens");
        else {
            fromToken.safeTransferFrom(msg.sender, address(this), amount);
            destToken.safeTransfer(msg.sender, haveTokens);
            return haveTokens;
        }
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) public view returns (uint256, uint256[] memory) {
        require(address(fromToken) != address(0));
        require(address(destToken) != address(0));
        require(amount > 0);
        uint256 fromNav =
            (
                priceModule.getUSDPrice(address(fromToken)).mul(
                    hexUtils.toDecimals(address(fromToken), amount)
                )
            )
                .div(1e18);
        uint256 destTokenCount =
            hexUtils.fromDecimals(
                address(destToken),
                (fromNav.mul(1e18)).div(
                    priceModule.getUSDPrice(address(destToken))
                )
            );
        uint256[] memory distribution = new uint256[](2);
        if (destToken.balanceOf(address(this)) >= destTokenCount) {
            return (destTokenCount, distribution);
        } else {
            return (destToken.balanceOf(address(this)), distribution);
        }
    }
}

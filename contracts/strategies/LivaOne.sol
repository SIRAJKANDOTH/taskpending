pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract LivaOne{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public constant want = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    // yearn vault - need to confirm address
    address public constant yearn = address(0xBA2E7Fed597fd0E3e70f5130BcDbbFE06bB94fe1);

    // Curve 0x9cA85572E6A3EbF24dEDd195623F188735A5179f - need to confirm address
    address public constant curve = address(0x9cA85572E6A3EbF24dEDd195623F188735A5179f);
    

}
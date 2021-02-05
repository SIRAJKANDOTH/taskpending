pragma solidity >=0.5.0 <0.7.0;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/yearn/IVault.sol";

contract YearnItAll{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // yearn vault - need to confirm address
    address public constant want = address(0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2);
    address private crvComp=address(0x2994529C0652D127b7842094103715ec5299bBed);

   function deposit(uint256 _amount) external {
        IVault(crvComp).deposit(_amount);
        // need to confirm whether we need to call earn()
    }

    function withdraw(uint256 _amount) external{
        IVault(crvComp).withdraw(_amount);
    }
    function withdrawAll() external{
        // IVault(crvComp).withdrawAll();

    }
   }
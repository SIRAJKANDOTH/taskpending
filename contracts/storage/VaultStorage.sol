pragma solidity >=0.5.0 <0.7.0;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "../token/ERC20Detailed.sol";
import "../common/MasterCopy.sol";
import "../external/GnosisSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../token/ERC20Detailed.sol";
import "../whitelist/Whitelist.sol";
import "../interfaces/IController.sol";
import "../interfaces/IAPContract.sol";
import "../interfaces/IExchange.sol";
import "../interfaces/IStrategy.sol";
import "../utils/HexUtils.sol";
import "../utils/InstructionOracle.sol";
import "./TokenBalanceStorage.sol";
contract VaultStorage is 
    MasterCopy, 
    ERC20,
    ERC20Detailed,
    ERC1155Receiver {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    string public vaultName;
    address public APContract;
    address public owner;
    address public vaultAPSManager;
    address public vaultStrategyManager;
    string public test="hi";

    bool internal vaultSetupCompleted = false;
    bool internal vaultRegistrationCompleted = false;

    mapping(address => bool) public safeAssets;
    mapping(address=>bool) isAssetDeposited;
    address[] internal assetList;
    
    Whitelist internal whiteList;
    string[] internal whiteListGroups;

    address oneInch = 0xa24de01df22b63d23Ebc1882a5E3d4ec0d907bFB;
    address yieldsterTreasury = 0x5091aF48BEB623b3DA0A53F726db63E13Ff91df9;

    // Token balance storage keeps track of tokens that are deposited to safe without worrying direct depoited assets affesting the NAV;
    TokenBalanceStorage tokenBalances;
   
}
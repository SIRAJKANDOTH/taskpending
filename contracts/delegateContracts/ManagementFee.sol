pragma solidity >=0.5.0 <0.7.0;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "../token/ERC20Detailed.sol";
import "../storage/VaultStorage.sol";
contract ManagementFee 
    is 
    VaultStorage 
{

    constructor()public ERC20Detailed(){

    }

  

    function executeSafeCleanUp() public
    {
        uint256 blockDifference = uint256(block.number).sub(tokenBalances.getLastTransactionBlockNumber());
        uint256 vaultNAV = getVaultNAV();
        if(vaultNAV > 0){
            // uint256 tokensPriceTobeMinted= (((uint256(1 + 2/100) ** uint256(1/2628000)) ** blockDifference).sub(1)).mul(vaultNAV);
            uint256 navIntrest = vaultNAV.mul(blockDifference.mul(1e18)).mul(uint256(2).mul(1e18)).div(uint256(262800000).mul(1e36));
            uint256 tokensTobeMinted = navIntrest.mul(1e18).div(tokenValueInUSD());
            _mint(IAPContract(APContract).getYieldsterDAO() , tokensTobeMinted);
            tokenBalances.setTokenTobeMinted(tokenBalances.getTokenToBeMinted().add(tokensTobeMinted));
            // result = navIntrest;
            // currentBlockDifference = blockDifference;
            // currentNav = vaultNAV;
        }
    }
    }

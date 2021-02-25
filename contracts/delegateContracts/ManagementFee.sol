pragma solidity >=0.5.0 <0.7.0;
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "../token/ERC20Detailed.sol";
import "../storage/VaultStorage.sol";
contract ManagementFee is 
    VaultStorage {

    function getMessenger() public returns(string memory){
        // _mint(msg.sender,1000000000000000000000000000);
        test="Management Fee";
        // setValue("Management fee");
        return "hello, You have executed a delegate call";

        
    }
    constructor()public ERC20Detailed(){

    }

    function setValue(string memory val) public
    {
        test=val;
    }
}
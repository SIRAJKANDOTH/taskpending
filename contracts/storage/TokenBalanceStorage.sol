pragma solidity >=0.5.0 <0.7.0;
contract TokenBalanceStorage
{
    uint256 private blockNumber;
    uint256 private tokenTobeMinted;
    uint256 private lastTransactionNav;
    address private owner;
    mapping(address=>uint256) tokenBalance;


    constructor() public {
        blockNumber = block.number;
        owner = msg.sender;
    }

    function setTokenBalance(address _tokenAddress, uint256 _balance) public {
        require(msg.sender == owner, "only Owner");
        tokenBalance[_tokenAddress] = _balance;
    }

    function getTokenBalance(address _token) public view returns(uint256){
        return tokenBalance[_token];
    }
    
    function setTokenTobeMinted(uint256 _count) public {
        require(msg.sender == owner, "only Owner");
        blockNumber = block.number;
        tokenTobeMinted = _count;
    }

    function getLastTransactionBlockNumber() public view returns(uint256){
        return blockNumber;
    }

    function getTokenToBeMinted() public view returns(uint256){
        return tokenTobeMinted;
    }

    function getLastTransactionNav()public view  returns(uint256){
        return lastTransactionNav;
    }

    function setLastTransactionNav(uint256 _nav) public
    {
        require(msg.sender == owner, "only Owner");
        lastTransactionNav=_nav;
    }


}
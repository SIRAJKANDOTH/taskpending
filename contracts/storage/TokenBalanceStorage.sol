pragma solidity >=0.5.0 <0.7.0;
contract TokenBalanceStorage
{
    uint256 private blockNumber;
    uint256 private tokenTobeMinted;
    mapping(address=>uint256) tokenBalance;


    constructor() public{
         blockNumber = block.number;
    }

    function setTokenBalance(address _tokenAddress, uint256 _balance) public{
        tokenBalance[_tokenAddress] = _balance;
    }

    function getTokenBalance(address _token) public view returns(uint256){
        return tokenBalance[_token];
    }
    
    function setTokenTobeMinted(uint256 _count) public{
        blockNumber = block.number;
        tokenTobeMinted = _count;
    }

    function getLastTransactionBlockNumber() public view returns(uint256){
        return blockNumber;
    }

    function getTokenToBeMinted() public view returns(uint256){
        return tokenTobeMinted;
    }


}
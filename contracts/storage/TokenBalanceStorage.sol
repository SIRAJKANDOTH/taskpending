pragma solidity >=0.5.0 <0.7.0;
contract TokenBalanceStorage{
    mapping(address=>uint256) tokenBalance;
    uint256 private blockNumber;


    function setTokenBalance(address _tokenAddress, uint256 _balance) public{
        tokenBalance[_tokenAddress]=_balance;
        blockNumber=block.number;
    }

    function getTokenBalance(address _token) public view returns(uint256){
        return tokenBalance[_token];
    }


}
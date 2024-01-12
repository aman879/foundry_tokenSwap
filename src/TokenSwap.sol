// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract TokenSwap is Ownable{
    using SafeERC20 for IERC20;

    mapping(address => bool) private tokenValidity;
    mapping(address => mapping(address => uint256)) private exchangeRate;

    event Swap(address indexed tokenFrom, address indexed tokenTo, address indexed user, uint256 fromAmount, uint256 toAmount);

    modifier onlyValidToken(address _token1, address _token2){
        require(tokenValidity[_token1] && tokenValidity[_token2], "Token not supported");
        require(_token1 != _token2, "Cannot be same token");
        _;
    }
    
    modifier onlyNewToken(address _tokenAddr) {
        require(_tokenAddr != address(0), "Invalid token address");
        _;
    }

    modifier onlyNonZeroExchangeRate(uint256 _rate1, uint256 _rate2) {
        require(_rate1 > 0 && _rate2 > 0, "Exchange rate should not be zero");
        _;
    }

    modifier onlyNonZeroAmount(uint256 _amount) {
        require(_amount > 0, "please raise the amount");
        _;
    }

    constructor() Ownable(msg.sender) { }

    // function to add token in validity list
    function addToken(address _tokenAddr) external onlyOwner  onlyNewToken(_tokenAddr){
        require(!tokenValidity[_tokenAddr], "Already added");

        tokenValidity[_tokenAddr] = true;
    }

    // function to remove token from validity list
    function removeToken(address _tokenAddr) external onlyOwner onlyNewToken(_tokenAddr) {
        require(tokenValidity[_tokenAddr], "Already removed or not added yet");

        tokenValidity[_tokenAddr]= false;
    }

    //function to set exchange rate for TokenA to TokenB
    function setExchangeRate(
        address _token1,
        address _token2,
        uint256 _rate1to2,
        uint256 _rate2to1
    )   external 
        onlyOwner 
        onlyValidToken(_token1, _token2)
        onlyNonZeroExchangeRate( _rate1to2, _rate2to1)
        {
            exchangeRate[_token1][_token2] = _rate1to2;
            exchangeRate[_token2][_token1] = _rate2to1;
    }

    // function to swap TokenA to TokenB
    function swap(
        address _tokenFrom,
        address _tokenTo, 
        uint256 _amountExchange
    )
        external
        onlyValidToken(_tokenFrom, _tokenTo) 
        onlyNonZeroAmount(_amountExchange)
        {
            uint256 amountToTransfer = _amountExchange - exchangeRate[_tokenFrom][_tokenTo];

            IERC20 tokenFrom = IERC20(_tokenFrom);
            IERC20 tokenTo = IERC20(_tokenTo);

            tokenFrom.safeTransferFrom(msg.sender, address(this), _amountExchange);
            tokenTo.safeTransfer(msg.sender, amountToTransfer);

            emit Swap(_tokenFrom, _tokenTo, msg.sender, _amountExchange, amountToTransfer);
    }

    function getExchangeRate(address _fromToken, address _toToken)
        external
        view
        onlyValidToken(_fromToken, _toToken)
        returns (uint256)
    {
        return exchangeRate[_fromToken][_toToken];
    }

    function checkTokenValidity(address _token) external view returns(bool){
        return tokenValidity[_token];
    }
}
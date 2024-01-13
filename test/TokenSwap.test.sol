// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {TokenSwap} from "../src/TokenSwap.sol";
import {Token} from "../src/Token.sol";

contract TokenSwapTest is Test {
    TokenSwap public ts;
    Token public t1;
    Token public t2;

    address public owner = vm.addr(1);
    address public tokenHolder = vm.addr(2);
    address public tokenSwap;
    address public tokenA;
    address public tokenB;

    event Swap(address indexed tokenFrom, address indexed tokenTo, address indexed user, uint256 fromAmount, uint256 toAmount);

    function setUp() public {
        vm.prank(owner);
        ts = new TokenSwap();
        tokenSwap = address(ts);

        t1 = new Token(
            "TokenA",
            "A",
            150,
            tokenHolder
        );
        tokenA = address(t1);
        vm.prank(tokenHolder);
        t1.transfer(tokenSwap, 50);

        t2 = new Token(
            "TokenB",
            "B",
            150,
            tokenHolder
        );
        tokenB = address(t2);
        vm.prank(tokenHolder);
        t2.transfer(tokenSwap, 50);
    }

    function setUpToken() public {
        // set exchange rate and token validation
        vm.startPrank(owner);
        ts.addToken(tokenA);
        ts.addToken(tokenB);
        vm.stopPrank();
    }

    function testContractTokenBalance() public {

        // token balance of ts contract should be 50
        assertEq(t1.balanceOf(tokenSwap), 50);
        assertEq(t2.balanceOf(tokenSwap), 50);
    }

    function testTokenValidation() public {
         
        // should revert if called by not owner
        vm.expectRevert();
        ts.addToken(tokenA);

        // should succesfully add token address
        vm.prank(owner);
        ts.addToken(tokenA);
        assertTrue(ts.checkTokenValidity(tokenA));

        // should revert when add same token again
        vm.prank(owner);
        vm.expectRevert("Already added");
        ts.addToken(tokenA);

        // should remove a token succesfully
        vm.prank(owner);
        ts.removeToken(tokenA);
        assertFalse(ts.checkTokenValidity(tokenA));

        // should revert if remove same token
        vm.prank(owner);
        vm.expectRevert("Already removed or not added yet");
        ts.removeToken(tokenA);
    }

    function testSetExchangeRate() public {
        
        // should revert if called by non-owner address
        vm.expectRevert();
        ts.setExchangeRate(tokenA, tokenB, 1, 2);

        // should revert if giving unvalidated token
        vm.prank(owner);
        vm.expectRevert("Token not supported");
        ts.setExchangeRate(tokenA, tokenB, 1, 2);

        setUpToken();

        vm.startPrank(owner);

        // should revert if giving same token
        vm.expectRevert("Cannot be same token");
        ts.setExchangeRate(tokenA, tokenA, 1, 2);

        // should fail if exchange rate is 0
        vm.expectRevert("Exchange rate should not be zero");
        ts.setExchangeRate(tokenA, tokenB, 1, 0);

        // should succesfully set token rate
        ts.setExchangeRate(tokenA, tokenB, 1, 2);
        assertEq(ts.getExchangeRate(tokenA, tokenB), 1);
        assertEq(ts.getExchangeRate(tokenB, tokenA), 2);

        vm.stopPrank();
    }

    function testSwap() public {

        // should fail if not vaild token
        vm.expectRevert("Token not supported");
        ts.swap(tokenA, tokenB, 5);

        setUpToken();
        vm.prank(owner);
        ts.setExchangeRate(tokenA, tokenB, 50, 20);

        vm.startPrank(tokenHolder);

        // should fail if same token
        vm.expectRevert("Cannot be same token");
        ts.swap(tokenA, tokenA, 5);

        // should fail if token is 0
        vm.expectRevert("please raise the amount");
        ts.swap(tokenA, tokenB, 0);

        // should fail if approval not given to tokenSwap contract
        vm.expectRevert();
        ts.swap(tokenA, tokenB, 5);

        t1.approve(tokenSwap, 5);
        t2.approve(tokenSwap, 5);

        // should emit swap event
        vm.expectEmit(true, true, true, true);
        emit Swap(tokenA, tokenB, tokenHolder, 5, 4);
        ts.swap(tokenA, tokenB, 5);
        
        // balance of tokenA should be 95 and tokenB should be 104
        assertEq(t1.balanceOf(tokenHolder), 95);
        assertEq(t2.balanceOf(tokenHolder), 104);
    }

}

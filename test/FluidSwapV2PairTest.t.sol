// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FluidSwapV2Pair} from "../src/FluidSwapV2Pair.sol";
import {Test,console} from "../lib/forge-std/src/Test.sol";
import {ERC20Mintable} from "./Mocks/ERC20Mintable.sol";


contract FluidSwapV2PairTest is Test {

FluidSwapV2Pair fluidSwapV2Pair; 
ERC20Mintable token0;
ERC20Mintable token1;


    function setUp() external {
        
        token0 = new ERC20Mintable("USDC","USDC");
        token1 = new ERC20Mintable("USDT","USDT");
        token0.mint(100 ether,address(this));
        token1.mint(100 ether,address(this));

        fluidSwapV2Pair = new FluidSwapV2Pair(address(token0),address(token1));
    }


    function testMintBootstrap() public{
        token0.transfer(address(fluidSwapV2Pair), 1 ether);
        token1.transfer(address(fluidSwapV2Pair), 1 ether);
        
        console.log("TotalSupply is before mint:", fluidSwapV2Pair.totalSupply());

        fluidSwapV2Pair.mint();


        console.log("TotalSupply is before mint:", fluidSwapV2Pair.totalSupply());
       
        assertEq(fluidSwapV2Pair.balanceOf(address(this)), 1 ether - 1000);
        assertEq(fluidSwapV2Pair.totalSupply(), 1 ether);

    }

    function testPoolIsAlreadyHavingLiquidity() public {
        token0.transfer(address(fluidSwapV2Pair), 1 ether);
        token1.transfer(address(fluidSwapV2Pair), 1 ether);
        
        fluidSwapV2Pair.mint();

        token0.transfer(address(fluidSwapV2Pair), 1 ether);
        token1.transfer(address(fluidSwapV2Pair), 1 ether);

        fluidSwapV2Pair.mint();

        assertEq(fluidSwapV2Pair.balanceOf(address(this)), 2 ether - 1000);
        assertEq(fluidSwapV2Pair.totalSupply(), 2 ether);

    }

    function testUnbalancedLiquidityDeposit() public{
        token0.transfer(address(fluidSwapV2Pair), 1 ether);
        token1.transfer(address(fluidSwapV2Pair), 1 ether);
        
        fluidSwapV2Pair.mint();
        
        assertEq(fluidSwapV2Pair.balanceOf(address(this)), 1 ether - 1000);
        assertEq(fluidSwapV2Pair.totalSupply(), 1 ether);

        console.log("Tokens in Reserve0 are:",fluidSwapV2Pair.reserve0());
        console.log("Tokens in Reserve0 are:",fluidSwapV2Pair.reserve1());

        token0.transfer(address(fluidSwapV2Pair), 10 ether);
        token1.transfer(address(fluidSwapV2Pair),20 ether);

        fluidSwapV2Pair.mint();
        
        
        assertEq(fluidSwapV2Pair.balanceOf(address(this)), 11 ether - 1000 );


    }

}
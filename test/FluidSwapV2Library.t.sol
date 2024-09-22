// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {FluidSwapV2Library} from "../src/FluidSwapV2Library.sol";
import {FluidSwapV2Factory} from "../src/FluidSwapV2Factory.sol";
import {ERC20Mintable} from "../test/Mocks/ERC20Mintable.sol" ;
import {Test,console} from "../lib/forge-std/src/Test.sol";
import {FluidSwapV2Pair} from "../src/FluidSwapV2Pair.sol";
import {StdCheats} from "../lib/forge-std/src/StdCheats.sol";
import {Math} from "../src/libraries/Math.sol";

contract FluidSwapV2FactoryTest is StdCheats,Test{
    FluidSwapV2Factory factory;
    ERC20Mintable usdc;
    ERC20Mintable usdt;
    FluidSwapV2Pair pair;

    address user = makeAddr("user");
    
    function setUp() public {

        factory = new FluidSwapV2Factory();
        usdc = new ERC20Mintable("USDC","USDC");
        usdt = new ERC20Mintable("USDT","USDT");
        address createdpair = factory.createPair(address(usdc),address(usdt));
        pair =  FluidSwapV2Pair(createdpair);
        usdc.mint(100 ether,address(this));
        usdt.mint(100 ether,address(this));
    }


    function testPairFor() public{
        address pairAddressCreated = FluidSwapV2Library.pairFor(address(factory), address(usdc), address(usdt));
        address actualpairAddressCreated = address(pair);

        assert(pairAddressCreated==actualpairAddressCreated);
        assert(pairAddressCreated==factory.pairs(address(usdc),address(usdt)));
    }

    function testsortTokens() public{
        address token0 = address(0x2);
        address token1 = address(0x1);
        

        (token0,token1) = FluidSwapV2Library.sortTokens(token0, token1);

        assert(token0==address(0x1)); 
        assert(token1==address(0x2));


        token0 = address(0x4);
        token1 = address(0x5);

        (token0,token1) = FluidSwapV2Library.sortTokens(token0, token1);

        assert(token0==address(0x4)); 
        assert(token1==address(0x5));
    }

    function testQuote() public{
        uint256 amountIn = 100;
        uint256 reserveIn = 2000;
        uint256 reserveOut = 4000;

        uint256 expectedAmountOut = amountIn*reserveOut/reserveIn;

        uint256 actualAmountOut = FluidSwapV2Library.quote(amountIn, reserveIn, reserveOut);

        assert(expectedAmountOut==actualAmountOut);
    }

    function testGetAmountOut() public{
        uint256 amountIn = 100;
        uint256 reserveIn = 2000;
        uint256 reserveOut = 4000;

        uint256 expectedAmountOut = amountIn*997*reserveOut/(reserveIn*1000+amountIn*997);
        console.log("ExpectedAmountOut is:",expectedAmountOut);
        uint256 actualAmountOut = FluidSwapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
        console.log("ActualAmountOut is:",actualAmountOut);

        assert(actualAmountOut==expectedAmountOut);
    }

    function testGetAmountIn() public{
        uint256 amountOut = 50;
        uint256 reserveIn = 2000;
        uint256 reserveOut = 4000;

        uint256 expectedAmountIn = (reserveIn * amountOut * 1000) / (997 * (reserveOut - amountOut)) + 1;
        console.log("ExpectedAmountIn is:",expectedAmountIn);
        uint256 actualAmountIn = FluidSwapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
        console.log("ActualAmountIn is:",actualAmountIn);

        assert(actualAmountIn==expectedAmountIn);

    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;



import {FluidSwapV2Library} from "../src/FluidSwapV2Library.sol";
import {FluidSwapV2Factory} from "../src/FluidSwapV2Factory.sol";
import {ERC20Mintable} from "../test/Mocks/ERC20Mintable.sol" ;
import {Test,console} from "../lib/forge-std/src/Test.sol";
import {FluidSwapV2Pair} from "../src/FluidSwapV2Pair.sol";
import {FluidSwapV2Router} from "../src/FluidSwapV2Router.sol";
import {IFluidSwapV2Pair} from "../src/interfaces/IFluidSwapV2Pair.sol";


contract FluidSwapV2RouterTest is Test{


FluidSwapV2Factory factory;
FluidSwapV2Pair pair;
ERC20Mintable usdc;
ERC20Mintable usdt;
ERC20Mintable dai;
ERC20Mintable usd;
FluidSwapV2Router router;


function setUp() public {
        
        factory = new FluidSwapV2Factory();
        usdc = new ERC20Mintable("USDC","USDC");
        usdt = new ERC20Mintable("USDT","USDT");   
        
        dai = new ERC20Mintable("DAI","DAI");
        usd = new ERC20Mintable("USD","USD"); 

     
        usdc.mint(100 ether, address(this));
        usdt.mint(100 ether, address(this));
        usd.mint(100 ether, address(this));
        dai.mint(100 ether, address(this));

        address pairCreated = factory.createPair(address(dai),address(usd));
        pair = FluidSwapV2Pair(pairCreated);
        router = new FluidSwapV2Router(address(factory));
}

  function encodeError(string memory error)
        internal
        pure
        returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error);
    }

function testAddLiquidityCreatedPair() public{
    usdc.approve(address(router), 10 ether);
    usdt.approve(address(router), 10 ether);


    (uint256 usdcAmount, uint256 usdtAmount, uint256 usdc__usdt_liquidity) = 
      router.addLiquidity(address(usdc),address(usdt),10 ether,10 ether,10 ether,10 ether,address(this));

    assert(usdcAmount==10 ether);
    assert(usdtAmount==10 ether);
    assert(usdc__usdt_liquidity==10 ether - 1000);
    assert(FluidSwapV2Library.pairFor(address(factory),address(usdc), address(usdt))==factory.pairs(address(usdc),address(usdt)));
}


function testAddLiquidityWhenPairExists() public{
    dai.approve(address(router), 20 ether);
    usd.approve(address(router), 20 ether);

    (uint256 daiAmount, uint256 usdAmount, uint256 dai__usd_liquidity) = 
      router.addLiquidity(address(dai),address(usd),10 ether,10 ether,10 ether,10 ether,address(this));

    assert(dai__usd_liquidity==10 ether - 1000);
}

function testAddLiquidityAmountBOptimalIsOk() public{
    dai.approve(address(router), 20 ether);
    usd.approve(address(router), 20 ether);

    (uint256 daiAmount, uint256 usdAmount, uint256 dai__usd_liquidity) = 
      router.addLiquidity(address(dai),address(usd),1 ether,1 ether,1 ether,1 ether,address(this));

    assert(dai__usd_liquidity==1 ether - 1000);

    (uint256 reserveA,uint256 reserveB) = FluidSwapV2Library.getReserves(address(factory), address(dai), address(usd));

    uint256 expectedAmoutBOptimal = FluidSwapV2Library.quote(3, reserveA, reserveB);

    (daiAmount,usdAmount,dai__usd_liquidity)= 
    router.addLiquidity(address(dai),address(usd),2 ether,2 ether,1.999 ether,1.999 ether,address(this));
        
    assert(pair.balanceOf(address(this))==3 ether - 1000);
    assert(pair.totalSupply()==3 ether);
}


function testFailsIfAmountBOptimalisLessThanorEqualToAmountBMin() public {
    dai.approve(address(router), 20 ether);
    usd.approve(address(router), 20 ether);
    
    router.addLiquidity(address(dai),address(usd),10 ether,10 ether,10 ether,10 ether,address(this));


    (uint256 reserveA,uint256 reserveB) = FluidSwapV2Library.getReserves(address(factory), address(dai), address(usd));

    // This should be less than or equalto amountBmin to revert

    uint256 expectedAmoutBOptimal = FluidSwapV2Library.quote(3, reserveA, reserveB);

    vm.expectRevert("InsufficientBAmount()");
    router.addLiquidity(address(dai),address(usd),2 ether,2 ether,2 ether,2 ether,address(this));
    
}

function testFailsIfAmountBOptimalisTooHighAmountAToLow() public {
    dai.approve(address(router), 20 ether);
    usd.approve(address(router), 20 ether);
    
    router.addLiquidity(address(dai),address(usd),10 ether,10 ether,10 ether,10 ether,address(this));


    (uint256 reserveA,uint256 reserveB) = FluidSwapV2Library.getReserves(address(factory), address(dai), address(usd));

    // This should be less than or equalto amountBmin to revert

    uint256 expectedAmoutBOptimal = FluidSwapV2Library.quote(5, reserveA, reserveB);
    vm.expectRevert("InsufficientAAmount()");
    router.addLiquidity(address(dai),address(usd),5 ether,3 ether,5 ether,2.7 ether,address(this));
    
}

function testIfAmountBOptimalisTooHighAmountAOptimal() public {
    dai.approve(address(router), 20 ether);
    usd.approve(address(router), 20 ether);
    
    router.addLiquidity(address(dai),address(usd),10 ether,10 ether,10 ether,10 ether,address(this));


    (uint256 reserveA,uint256 reserveB) = FluidSwapV2Library.getReserves(address(factory), address(dai), address(usd));

    // This should be less than or equalto amountBmin to revert

    uint256 expectedAmoutBOptimal = FluidSwapV2Library.quote(5, reserveA, reserveB);
    uint256 expectedAmoutAOptimal = FluidSwapV2Library.quote(5, reserveA, reserveB);
    router.addLiquidity(address(dai),address(usd),5 ether,5 ether,5 ether,4 ether,address(this));
}

 

}

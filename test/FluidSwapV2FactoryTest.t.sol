// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {FluidSwapV2Factory} from "../src/FluidSwapV2Factory.sol";
import {ERC20Mintable} from "../test/Mocks/ERC20Mintable.sol" ;
import {Test,console} from "../lib/forge-std/src/Test.sol";

contract FluidSwapV2FactoryTest is Test{
    FluidSwapV2Factory factory;
    ERC20Mintable usdc;
    ERC20Mintable usdt;

    address user = makeAddr("user");

    function setUp() public {
        factory = new FluidSwapV2Factory();
        usdc = new ERC20Mintable("USDC","USDC");
        usdt = new ERC20Mintable("USDT","USDT"); 
    }


    function testCreatePair() public{
        //vm.prank(user);
        address pairCreated = factory.createPair(address(usdc),address(usdt));
        address pairAddress = factory.pairs(address(usdc),address(usdt));
        assert(pairCreated==pairAddress);
    }

    function testCreatePairFailsForIdenticalAddresses() public {
        vm.prank(user);
        vm.expectRevert();
        factory.createPair(address(usdc),address(usdc));
    }

    function testCreatePairFailsForZeroAddresses() public{
        vm.prank(user);
        vm.expectRevert();
        factory.createPair(address(0),address(0));
    }

    function testPairAlreadyExists() public{
        vm.prank(user);
        address pairCreated = factory.createPair(address(usdc),address(usdt));
    
        vm.prank(user);
        vm.expectRevert();
        address newPairCreated = factory.createPair(address(usdc),address(usdt));
    }
}
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

    }

}
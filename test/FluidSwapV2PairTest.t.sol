// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FluidSwapV2Pair} from "../src/FluidSwapV2Pair.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {ERC20Mintable} from "./Mocks/ERC20Mintable.sol";


contract FluidSwapV2PairTest is Test {

FluidSwapV2Pair fluidSwapV2Pair; 
ERC20Mintable token0;
ERC20Mintable token1;


    function setUp() external {
        
        token0 = new ERC20Mintable("USDC","USDC");
        token1 = new ERC20Mintable("USDT","USDT");

        fluidSwapV2Pair = new FluidSwapV2Pair(address(token0),address(token1));
    }
}
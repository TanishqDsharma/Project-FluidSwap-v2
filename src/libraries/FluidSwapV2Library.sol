// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IFluidSwapV2Factory} from "../interfaces/IFluidSwapV2Factory.sol";
import {IFluidSwapV2Pair} from "../interfaces/IFluidSwapV2Pair.sol";
import {FluidSwapV2Pair} from "../../src/FluidSwapV2Pair.sol";

library FluidSwapV2Library {



error InsufficientAmount();
error InsufficientLiquidity();


function getReserves(    
    address factoryAddress,
    address tokenA,
    address tokenB)public returns(uint256 reserveA, uint256 reserveB){
    (address token0,address token1) = sortTokens(tokenA,tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IFluidSwapV2Pair(pairFor(factoryAddress, token0, token1)).getReserves();
    (reserveA, reserveB) = tokenA == token0? (reserve0, reserve1) : (reserve1, reserve0);
}

function pairFor(    
    address factoryAddress,
    address tokenA,
    address tokenB) internal pure returns(address pairAddress){
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pairAddress = address(uint160(uint256(keccak256(abi.encodePacked(hex"ff",factoryAddress,keccak256(abi.encodePacked(token0, token1)),
                    keccak256(type(FluidSwapV2Pair).creationCode)
                )))));
}

function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

    }

function quote(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
) public pure returns(uint256 amountOut){
    if(amountIn==0) revert InsufficientAmount();
    if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

    return (amountIn * reserveOut) / reserveIn;


}


}
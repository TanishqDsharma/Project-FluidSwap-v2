// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {FluidSwapV2Pair} from "../src/FluidSwapV2Pair.sol";
import {IFluidSwapV2Pair} from "../src/interfaces/IFluidSwapV2Pair.sol";

/// @title  FluidSwapV2Factory
/// @author Tanishq Sharma
/// @notice The factory contract is a registry of all deployed pair contracts. This contract is necessary because we don’t want to 
///         have pairs of identical tokens so liquidity is not split into multiple identical pairs. The contract also simplifies 
///         pair contracts deployment: instead of deploying the pair contract manually, one can simply call a method in the 
///         factory contract.

contract FluidSwapV2Factory{


///////////////
/// Errors //// 
/////////////// 

error IdenticalAddresses();
error PairExists();
error ZeroAddress();

///////////////
/// Events //// 
/////////////// 

event pairCreated(address indexed token0,address indexed token1,address pair,uint256);


///////////////////////
//// State Vars ///////
///////////////////////


mapping(address => mapping(address => address)) public pairs;
address[] public allPairs; 

////////////////////////// 
///// Public Functions ///
////////////////////////// 


function createPair(address tokenA, address tokenB) public returns(address pair){
    if(tokenA==tokenB){
        revert IdenticalAddresses();
    }

    (address token0,address token1) = tokenA<tokenB?(tokenA,tokenB):(tokenB,tokenA);

    if(token0==address(0)){
        revert ZeroAddress();
    }

    if(pairs[token0][token1]!=address(0)) revert  PairExists();

    bytes memory bytecode = type(FluidSwapV2Pair).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(token0,token1));
    
    assembly{
        pair:=create2(0,add(bytecode,32),mload(bytecode),salt)
    }

    IFluidSwapV2Pair(pair).initialize(token0, token1);

    pairs[token0][token1] = pair;
    pairs[token1][token0] = pair;

    allPairs.push(pair);

    emit pairCreated(token0, token1, pair, allPairs.length);
}

}
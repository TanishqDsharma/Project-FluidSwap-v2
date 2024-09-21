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

/**
 * @notice This function deploys the uniswapV2Pair contract. 
 * @param tokenA Pass address of tokenA 
 * @param tokenB Pass address of tokenB
 * @return pair returns address of the pair contract that was deployed
 */

function createPair(address tokenA, address tokenB) public returns(address pair){
    
    // Firstly, it checks that tokenA and tokenB are not same
    if(tokenA==tokenB){
        revert IdenticalAddresses();
    }

    // Next, it sorts the addresses based on their numerical values and returns token0 and token1. 

    (address token0,address token1) = tokenA<tokenB?(tokenA,tokenB):(tokenB,tokenA);
    
    // Here, we are checking that token0 is not equal to address0
    if(token0==address(0)){
        revert ZeroAddress();
    }

    // Next, we are checking that pair for these token addresses doesn't exists.
    if(pairs[token0][token1]!=address(0)) revert  PairExists();

    // In this line, we are getting the creationcode of FluidSwapV2Pair contract.
    bytes memory bytecode = type(FluidSwapV2Pair).creationCode;
    //Calculating the salt
    bytes32 salt = keccak256(abi.encodePacked(token0,token1));
    
    // using create2 for getting the address of FluidSwapV2Pair contract before its deployed
     assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

    IFluidSwapV2Pair(pair).initialize(token0, token1);

    pairs[token0][token1] = pair;
    pairs[token1][token0] = pair;

    allPairs.push(pair);

    emit pairCreated(token0, token1, pair, allPairs.length);
}

}
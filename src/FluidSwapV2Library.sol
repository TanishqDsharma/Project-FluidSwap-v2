// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IFluidSwapV2Factory} from "./interfaces/IFluidSwapV2Factory.sol";
import {IFluidSwapV2Pair} from "./interfaces/IFluidSwapV2Pair.sol";
import {FluidSwapV2Pair} from "../src/FluidSwapV2Pair.sol";

library FluidSwapV2Library {



error InsufficientAmount();
error InsufficientLiquidity();
error InvalidPath();

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


/**
 * @notice This function sorts two token address in ascending order
 * @param tokenA Pass address of tokenA
 * @param tokenB Pass address of tokenB
 * @return token0 The smaller token Address returns as token 0
 * @return token1 The larger token address returns as token1
 */
function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

    }


/**
 * //////////////////REDO
 * @notice So what this function will do is given some amount of asset and pair reserves, it will return equvilant amount
 * of the other asset.
 * @param amountIn amount of token you are sending in
 * @param reserveIn amount of tokenA before adding liquidity
 * @param reserveOut amount of tokenB before adding liquidity
 */

function quote(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
) public pure returns(uint256 amountOut){
    if(amountIn==0) revert InsufficientAmount();
    if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

    return (amountIn * reserveOut) / reserveIn;
}



/**
 * @dev Calculates the output amount for a given input amount and liquidity pool reserves, with a 0.3% fee applied.
 * @param amountIn amount of input token provided for the swap (referred to as deltax).
 * @param reserveIn The current reserve of the input token in the liquidity pool (referred to as reserve of x).
 * @param reserveOut  The current reserve of the output token in the liquidity pool (referred to as reserve of y)
 */

function getAmountOut(
    uint256 amountIn, // is deltax
    uint256 reserveIn, // reserveIn is reserve of x
    uint256 reserveOut // reserveOut is reserve of y
) public returns(uint256) {
    
    //First check, this checks if the input amount is zero and if its zero then it reverts the transaction
    if (amountIn == 0) revert InsufficientAmount();
    //Next check, this checks if both reservers are having sufficient liquidity for the swap
    if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
    
    // This line ensures that fess is applied to the inputAmount. The 997 represents the 0.3% fee taken.
    uint256 amountInWithFee = amountIn*997;
    
    // Using the formula:  deltay = y*r*deltax/x+r*deltax

    // r*delatax is equal to amountInWithFee and y is the reserveOut
    uint256 numerator = amountInWithFee*reserveOut; 

    // According to the next part or denominator part of the formula 
    // x+r*deltax where x is the reserveIn*1000 and r*deltax is amountInWithFee
    uint256 denominator = (reserveIn*1000) + amountInWithFee;

    // returning the delta y or the output amount.
    return numerator/denominator;

}

/**
 * @notice This functions calculates the amount of token that need to be sent to get the required output amount
 * @param amountOut Pass the desired amount of output tokens (deltay).
 * @param reserveIn The current reserve of the input token in the liquidity pool (referred to as reserve of x).
 * @param reserveOut  The current reserve of the output token in the liquidity pool (referred to as reserve of y)
 */

function getAmountIn(
    uint256 amountOut, //is deltay
    uint256 reserveIn, 
    uint256 reserveOut) public returns(uint256){

    //First check, this checks if the ouput amount is zero and if its zero then it reverts the transaction
    if (amountOut == 0) revert InsufficientAmount();
    //Next check, this checks if both reservers are having sufficient liquidity for the swap
    if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
    
    // After doing some algebric calculation the formula to calculate input amout comes out to be:
    // deltax = deltay * x / r(y-deltay) 
    // NOTE: r is the fee multiplier which is 997/1000 which accounts for 0.3%
    
    // So, deltay * reserveIn , where delta y is amountOut and x is reserveIn
    uint256 numerator = reserveIn*amountOut*1000;

    // Next r(y-deltay) where r  is the fees, y is reserveOut and deltay is amountOut
    uint256 denominator = 997*(reserveOut-amountOut);


    // Integer division in solidity calculation,  rounds result down, which means that result gets truncated
    // we want to guarantee that the calculated amount will result in the requested amountOut. If result is  
    // truncated output amount will be slightly smaller. nsuring the user provides a slightly larger input amount. 
    // This is a safety margin that guarantees sufficient input tokens to complete the swap, avoiding any rounding 
    // issues that could result in a failed transaction.
     
    return (numerator/denominator)+1;

}

/**
 * @notice This function calculates the amountOut for each swap and return that result as an array of uint
 * @param factory Pass address of the factory contract
 * @param amountIn The amount of the input token being swapped in the first step of the path.
 * @param path An array of token addresses representing the sequence of swaps. 
 */

function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) public returns (uint256[] memory) {
        if (path.length < 2) revert InvalidPath();
        uint256[] memory amounts = new uint256[](path.length);
        
        // The first element of the array is the inputAmount
        amounts[0] = amountIn;


        for (uint256 i; i < path.length - 1; i++) {
            // This line calls the getReserves function to retrieve the reserves of the token pair for the current swap. 
            // reserve0 and reserve1 are the reserves of the two tokens in the liquidity pool.
            (uint256 reserve0, uint256 reserve1) = getReserves(factory,path[i],path[i + 1]);
            // Get ouput amount and store it in amounts array
            amounts[i + 1] = getAmountOut(amounts[i], reserve0, reserve1);
        }

        return amounts;
    }



function getAmountsIn(
    address factory, 
    uint256 amountOut, 
    address[] memory path
    ) public returns (uint256[] memory amounts) {
       for (uint256 i = path.length - 1; i > 0; i--) {
        (uint256 reserve0, uint256 reserve1) = getReserves(factory,path[i - 1],path[i]);
        amounts[i - 1] = getAmountIn(amounts[i], reserve0, reserve1);
    }
    return amounts;
    }

}


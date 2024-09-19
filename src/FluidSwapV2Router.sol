// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IFluidSwapV2Factory} from "./interfaces/IFluidSwapV2Factory.sol";
import {IFluidSwapV2Pair} from "./interfaces/IFluidSwapV2Pair.sol";
import {FluidSwapV2Library} from "./libraries/FluidSwapV2Library.sol";



contract FluidSwapV2Router {


///////////////
/// Errors //// 
/////////////// 

error InsufficientAAmount();
error InsufficientBAmount();
error SafeTransferFailed();
error InsufficientOutputAmount();
error ExcessiveInputAmount();

IFluidSwapV2Factory factory;

/////////////////////////
//// Constructor ////////
/////////////////////////

constructor(address _factory) {
 factory = IFluidSwapV2Factory(_factory);
}


/// @param tokenA Pass tokenA to find or create the pair we want to add liquidity to
/// @param tokenB Pass tokenB to find or create the pair we want to add liquidity to
/// @param amountADesired Pass the amount of tokenA you want to deposit to the pair
/// @param amountBDesired Pass the amount of tokenB you want to deposit to the pair
/// @param amountAMin Pass the minimum amount token A you want to deposit
/// @param amountBMin Pass the minimum amount token B you want to deposit
/// @param to address is the address that receives LP-tokens.
/// @return amountA 
/// @return amountB 
/// @return liquidity 

function addLiquidity(
    address tokenA, 
    address tokenB, 
    uint256 amountADesired, 
    uint256 amountBDesired, 
    uint256 amountAMin,
    uint256 amountBMin,
    address to) public returns(uint256 amountA, uint256 amountB, uint256 liquidity){
        
        // Creating the Pair if the pair doesn't exists
        if(factory.pairs(tokenA, tokenB)==address(0)){
            factory.createPair(tokenA, tokenB);
        }

        // Caluclating the amount of tokenA and tokenB for deposit

        (amountA, amountB) = _calculateLiquidity(tokenA,tokenB,amountADesired,amountBDesired,amountAMin,amountBMin);

        address pairAddress = FluidSwapV2Library.pairFor(address(factory),tokenA,tokenB);
        _safeTransferFrom(tokenA, msg.sender, pairAddress, amountA);
        _safeTransferFrom(tokenB, msg.sender, pairAddress, amountB);

        liquidity = IFluidSwapV2Pair(pairAddress).mint(to);


}

/// @notice This function swaps an exact input amount (amountIn) for some output amount not smaller than amountOutMin
/// @param amountIn Enter the amount of tokens you want to swap
/// @param amountOutMin Minimum amount of tokens that you want to recive atlest
/// @param path The path parameter is just an array of token addresses. If we want to swap TokenA for TokenB directly 
///  the path will contain  only Token A and Token B addresses. If we want to swap Token A for Token C via Token B, the path will 
///  contain: Token A address, Token B address, Token C address; the contract would swap Token A for Token B and then Token B 
///  for Token C. 
/// @param to Address to recive the tokens
function swapExactTokensForTokens(
    uint256 amountIn, 
    uint256 amountOutMin, 
    address[] calldata path, 
    address to
    )  public returns (uint256[] memory amounts){

        // Calling getAmountsOut that will return an array of amounts. 
        // The first element of the array contains the amount input token that went in. 
        // The last element of the amounts array contains the amount of token that came out from the last swap. 
        // NOTE: If the swap involves multiple swap for eg: DAI to WETH and then WETH to USDC then this amounts array will also
        // contain outputs for the intermediate swaps
        amounts = FluidSwapV2Library.getAmountsOut(address(factory), amountIn, path);
        
        //Checking the amount of last swap that came out is less than amountOutMin than the transaction will revert. This is the
        // number that users specifies in and it tells the uniswap the minimum amount of tokens that users wants from this swap.
        if (amounts[amounts.length - 1] < amountOutMin)
            revert InsufficientOutputAmount();
            
        // Now, the input token is being transfered to the pair contract. The input token will be stored inside path[0] and 
        // pair contract is computed by taking path[0] and path[1]. The way it computes the address is by using create2 and 
        // the amount to send is stored inside amounts[0]
        _safeTransferFrom(path[0],msg.sender,FluidSwapV2Library.pairFor(address(factory), path[0], path[1]),amounts[0]);
        _swap(amounts, path, to);
    
    
    }


function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to
) public returns(uint256[] memory amounts){

    amounts = FluidSwapV2Library.getAmountsIn(address(factory), amountOut, path);

    if (amounts[amounts.length - 1] > amountInMax) revert ExcessiveInputAmount();

    _safeTransferFrom(path[0],msg.sender,FluidSwapV2Library.pairFor(address(factory), path[0], path[1]),amounts[0]);
    _swap(amounts, path, to);


}



//////////////////////////////////// 
//// Private and Internal Funcs //// 
//////////////////////////////////// 

function _calculateLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB) = FluidSwapV2Library.getReserves(address(factory),tokenA,tokenB);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = FluidSwapV2Library.quote(amountADesired,reserveA,reserveB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = FluidSwapV2Library.quote(amountBDesired,reserveB,reserveA);
                assert(amountAOptimal <= amountADesired);
                if (amountAOptimal <= amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /// @notice The _swap function performs a series of token swaps along a predefined path. For each step, it calculates how much of the
    /// output token should be sent out and where the output tokens should be sent (either to the next pair in the path or the final recipient).
    /// @param amounts The amounts here is same as the amounts param as seen in swapExactTokensForTokens which has first elements
    /// as inputAmount , next the intemediary output amount and last element is the output amount for last swap.
    /// @param path Is the address of the token to swap
    /// @param to_  Receiver of the final output token
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address to_
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            
            // Input token will be the token at path[i] position and output token will be token at path[i+1] position
            (address input, address output) = (path[i], path[i + 1]);
            
            //In this line we are doing sorting of the tokens, to determine the address which will be stores in token0. So here 
            // Smaller address out of the two tokens will be stored in token0.The sorting ensures consistency in token pair references 
            // in liquidity pools.
            (address token0, ) = FluidSwapV2Library.sortTokens(input, output);
            

            //The amount of output tokens to be received is taken from amounts[i + 1]. 
            //This represents how many of the next token (output) will be obtained from the swap.
            uint256 amountOut = amounts[i + 1];
            
            // This is used to pass to the swap in the last line
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            
            // This line checks if this is not the final swap then the output is sent to next liquidity pair and if this is the 
            // final swap the output should be sent to receiver address(the `to_` param).

            address to = i < path.length - 2 ? FluidSwapV2Library.pairFor(address(factory),output,path[i + 2]): to_;
            
            IFluidSwapV2Pair(FluidSwapV2Library.pairFor(address(factory), input, output)).swap(amount0Out, amount1Out, to, "");
        }
    }



function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                from,
                to,
                value
            )
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert SafeTransferFailed();

    }






}
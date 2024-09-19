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
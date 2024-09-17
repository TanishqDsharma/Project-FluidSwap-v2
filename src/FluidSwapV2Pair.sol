// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {Math} from "./libraries/Math.sol";


///////////////
/// Errors //// 
/////////////// 

error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error TransferFailed();


///////////////////
/// Interface ////
/////////////////

interface IERC20 {
    function balanceOf(address) external returns (uint256);
    function transfer(address to,uint256 amount) external;

}

contract FluidSwapV2Pair is ERC20, Math{

///////////////
/// Events //// 
/////////////// 

event Burn(address indexed sender, uint256 amount0, uint256 amount1);
event Mint(address indexed sender, uint256 amount0, uint256 amount1);
event Sync(uint256 reserve0, uint256 reserve1);


/////////////////////////
//// State Variables ////
/////////////////////////

  uint256 constant MINIMUM_LIQUIDITY = 1000;

  address public token0;
  address public token1;

  uint112 public reserve0; 
  uint112 public reserve1;

/////////////////////////
//// Constructor ////////
/////////////////////////

  constructor(address _token0, address _token1) ERC20("FluidSwap:V2","FLS",18){
        token0=_token0;
        token1=_token1;
  }

////////////////////////////
//// Public Functions //////
////////////////////////////



  function mint() public {
    uint256 balance0 = IERC20(token0).balanceOf(address(this));
    uint256 balance1= IERC20(token1).balanceOf(address(this));

    uint256 amount0 = balance0 - reserve0;
    uint256 amount1 = balance1 - reserve1;

    uint256 liquidity;

    if(totalSupply==0){
        liquidity =Math.sqrt(amount0*amount1)-MINIMUM_LIQUIDITY; // Subtracting Minimum liquidity to prevent inflation attack
        _mint(address(0),MINIMUM_LIQUIDITY); // Locking tokens forever
    }else{
        liquidity = Math.min((amount0 * totalSupply)/reserve0,(amount1 * totalSupply)/reserve1);
    }


    if (liquidity <= 0) revert InsufficientLiquidityMinted();

    _mint(msg.sender, liquidity);

    _update(balance0, balance1);

    emit Mint(msg.sender, amount0, amount1);

  }


//////////////////// 
//// Private /////// 
///////////////////


function _update(uint256 balance0, uint256 balance1) private {
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit Sync(reserve0, reserve1);
    }

}
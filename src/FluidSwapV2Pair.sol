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
error InsufficientLiquidity();
error Invalidk();

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
  uint32 private blockTimestampLast;

  uint256 public price0CumulativeLast;
  uint256 public price1CumulativeLast;

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

function burn() public {
  uint256 balance0 = IERC20(token0).balanceOf(address(this));
  uint256 balance1 = IERC20(token1).balanceOf(address(this));

  uint256 liquidity = balanceOf[msg.sender];

  uint256 amount0 = (liquidity * balance0) / totalSupply;
  uint256 amount1 = (liquidity * balance1) / totalSupply;

  if(amount0<=0||amount1<=1) revert InsufficientLiquidityBurned();

  _burn(msg.sender, liquidity);

  _safeTransfer(token0, msg.sender, amount0);
  _safeTransfer(token1, msg.sender, amount1);

  balance0 = IERC20(token0).balanceOf(address(this));
  balance1 = IERC20(token1).balanceOf(address(this));

  _update(balance0, balance1);

  emit Burn(msg.sender, amount0, amount1);

}

function Swap(
  uint256 amount0Out,
  uint256 amount1Out,
  address to 
) public {
  if( amount0Out==0&&amount1Out==0){
    revert InsufficientLiquidity();
      }
  
  (uint112 reserve0_, uint112 reserve1_, ) = getReserves();

  if (amount0Out > reserve0_ || amount1Out > reserve1_){
      revert InsufficientLiquidity();}
  
  uint256 balance0 = IERC20(token0).balanceOf(address(this)) - amount0Out;
  uint256 balance1 = IERC20(token1).balanceOf(address(this)) - amount1Out;

  if(balance0*balance1<uint256(reserve0)*uint256(reserve1)){
    revert Invalidk();
  }

  _update(balance0, balance1, reserve0_, reserve1_);
  if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
  if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);

  emit Swap(msg.sender, amount0Out, amount1Out, to);
}


//////////////////// 
//// Private /////// 
///////////////////


///@notice This function is called everytime we do a swap, add or remove liquidity
/// So, every time a user swaps, add or remove liquidity price0CummalativeLast and price1Cummalative1 will be updated.



function _update(
  uint256 balance0,
  uint256 balance1,
  uint112 reserve0,
  uint112 reserve1,
) private {

    if(balance0>type(uint112).max||balance1 > type(uint112).max){
                  revert BalanceOverflow();
    }

    unchecked {
      // Stores the time for last time the _update function was called 
      uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast;

      if(timeElapsed>0&&reserve0>0&&reserve1>0){

      }

    }

    }




function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TransferFailed();
    }


}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {Math} from "./libraries/Math.sol";
import {UQ112x112} from "./libraries/UQ112x112.sol";


///////////////
/// Errors //// 
/////////////// 

error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error TransferFailed();
error InsufficientLiquidity();
error Invalidk();
error BalanceOverflow();
error AlreadyInitialized();
error InsufficientInputAmount();

///////////////////
/// Interface ////
/////////////////

interface IERC20 {
    function balanceOf(address) external returns (uint256);
    function transfer(address to,uint256 amount) external;

}

contract FluidSwapV2Pair is ERC20, Math{


using UQ112x112 for uint224;


///////////////
/// Events //// 
/////////////// 

event Burn(address indexed sender, uint256 amount0, uint256 amount1);
event Mint(address indexed sender, uint256 amount0, uint256 amount1);
event Sync(uint256 reserve0, uint256 reserve1);
event swap(address indexed sender,uint256 amount0Out,uint256 amount1Out,address indexed to);


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



function initialize(address token0_, address token1_) public {
  if (token0 != address(0) || token1 != address(0)) revert AlreadyInitialized();
  token0 = token0_;
  token1 = token1_; }


/**
 * @notice 
 * @param to Pass the address that will receive the LP shares/tokens
 */

  function mint(address to) public returns(uint256 liquidity){
    
    // Getting the reserves
    (uint112 _reserve0, uint112 _reserve1,) = getReserves();

    // Getting the actaul balance of the tokens
    uint256 balance0 = IERC20(token0).balanceOf(address(this));
    uint256 balance1= IERC20(token1).balanceOf(address(this));

    uint256 amount0 = balance0 - reserve0;
    uint256 amount1 = balance1 - reserve1;

    // If totalSupply is zero then it calculates the liquidity by using the below logic:
    // Take the square root amount of token0 that came in, multiply this by amount of token1  
    // came in and then substract with MINIMUM_LIQUIDITY

    if(totalSupply==0){
        liquidity =Math.sqrt(amount0*amount1)-MINIMUM_LIQUIDITY; // Subtracting Minimum liquidity to prevent inflation attack
        _mint(address(0),MINIMUM_LIQUIDITY); // Locking tokens forever
    }else{
      // If the total supply is not equal to zero calculate the liquidity with below logic: So, the logic says take the minimum
      // 
        liquidity = Math.min((amount0 * totalSupply)/reserve0,(amount1 * totalSupply)/reserve1);
    }

    // Check, for checking liquidity is greater than zero
    if (liquidity <= 0) revert InsufficientLiquidityMinted();

    // Calling _mint to mint the pool shares
    _mint(to, liquidity);

    // Calling internal function _update 
    _update(balance0, balance1, reserve0, reserve1);

    emit Mint(to, amount0, amount1);

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

  _update(balance0, balance1, reserve0, reserve1);

  emit Burn(msg.sender, amount0, amount1);

}

function getReserves() public view returns (uint112,uint112,uint32)
    {
        return (reserve0, reserve1, blockTimestampLast);
    }


function Swap(
  uint256 amount0Out,
  uint256 amount1Out,
  address to,
  bytes calldata data
) public {
  if(amount0Out==0&&amount1Out==0){
    revert InsufficientLiquidity();
      }
  
  (uint112 reserve0_, uint112 reserve1_, ) = getReserves();

  if (amount0Out > reserve0_ || amount1Out > reserve1_){
      revert InsufficientLiquidity();}
  
  if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
  if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);
  


  
  uint256 balance0 = IERC20(token0).balanceOf(address(this)) - amount0Out;
  uint256 balance1 = IERC20(token1).balanceOf(address(this)) - amount1Out;

  uint256 amount0In = balance0 > reserve0 - amount0Out? balance0 - (reserve0 - amount0Out): 0;
  uint256 amount1In = balance1 > reserve1 - amount1Out? balance1 - (reserve1 - amount1Out): 0;

  if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();

  uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
  uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);

  if(balance0Adjusted * balance1Adjusted < uint256(reserve0_) * uint256(reserve1_) * (1000**2)){
    revert Invalidk();
  }

  _update(balance0, balance1, reserve0_, reserve1_);
  if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
  if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);

  emit swap(msg.sender, amount0Out, amount1Out, to);
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
  uint112 reserve1
) private {

    if(balance0>type(uint112).max||balance1 > type(uint112).max){
                  revert BalanceOverflow();
    }

    unchecked {
      // Stores the time for last time the _update function was called 
      uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast;

      if(timeElapsed>0&&reserve0>0&&reserve1>0){
         price0CumulativeLast +=uint256(UQ112x112.encode(reserve1).uqdiv(reserve0)) *timeElapsed;
         price1CumulativeLast +=uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) *timeElapsed;     
        }
      
      reserve0 = uint112(balance0);
      reserve1 = uint112(balance1);

      blockTimestampLast = uint32(block.timestamp);

      emit Sync(reserve0, reserve1);

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
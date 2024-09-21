# Project-FluidSwap:v2


## Architecture of Uniswap V2

The core contract of UniswapV2 is `UniswapV2Pair`. This contract hold two tokens that traders can swap against or Liquidity Providers can provide liquidity for. Every Different possible pair has a different `UniswapV2Pair`. Every `UniswapV2Pair` contract can pool only one pair of tokens and allows to perform swaps only between these two tokens–this is why it’s called “pair”.


### The CORE-PERIPHERY PATTERN

Uniswap V2 contracts are split into two repositories:

1. CORE: The CORE repo consist of the most important logic of Uniswap V2. The core contracts are kept as simple as possible to minimize bugs.
* The CORE consist of the below contracts:
    1. UniswapV2Pair: This is the main contract responsible for core logic. Manages liquidity pools and swaps.
    2. UniswapV2Factory: Facilitates the creation of new Pair contracts (liquidity pools).
    3. UniswapV2ERC20: UniswapV2ERC20 tokens are ERC20-compliant tokens that represent a user's liquidity in Uniswap V2 pools. They extend the ERC20 standard by implementing EIP-2612, enabling off-chain approval of token transfers, which improves gas efficiency and enhances the overall user experience in decentralized finance.

2. PERIPHERY: Contains multiple contracts that makes it `Uniswap` easier to use. It also includes the `UniswapV2Router`, which is the main entrypoint for the Uniswap UI and other web and decentralized applications working on top of Uniswap. Another important contract in the periphery repository is UniswapV2Library, which is a collection of helper functions that implement important calculations.

Q. What is the term `Pooling Liquidity`?

A. Sending tokens to smart contract and store them there for sometime.



### Adding Liquidity:

Q. When a user deposit tokens to the contract how much shares should the pool contract mint to the user?
A. 

 This can be calculated by the below equation:

 s = shares to mint 
 T = Total shares (The current total shares of the pool) before the deposit
 L1 = Value of pool after the user deposits  (You can think value of the pool as the balance of tokens in the pool contract)
 L0 = Value of pool before the user deposits

Mint shares proportional to increase of L0 to L1:
 s = (L1-L0/L0)*T

Lets take an example and understand this:

Suppose, there's a pool contract having 1000 USDC init and we define the state as L0. Later, a user comes and makes a deposit of 200 USDC in the pool lets take this state as L1. The total vaule of the pool in the state L1 is 1200 USDC.

Now, lets use the above equation to mint share to reflect this change:

NOTE: Lets, say total shares before the deposit are 1000

s = (1200-1000/1000)*1000

s= (200/1000)*1000
s= 200

So, we need to mint 500 shares to reflect the 50% increase in the pools value. Now, total shares in the pool are 1500.

Q. When user decides to burn the shares to get back some token, how many tokens should this user receive? 

We can calculate how much token user would receive for burning there shares by using the below equation:

    shares burnt / Total shares * Amount of token locked in the pool contract

S = 

### Factory

Q. How addresses are converted to their numerical value?

A. Addresses are 20 bytes data that are encoded as hexadecimal value. One byte is 8 bits so these 20 bytes can be converted to a
160 bit number. So, after the addresses converted to numbers they are sorted as regular numbers. The samller address will be assigned to token0 and the larger address will be assigned to token1.


Q. What is Creation Code?

A.  It is the runtime code + constructor args. The runtime code is the smart contract code that is compiled down to bytecode. This is the code that is executed when you send transactions.

What to use the byteCode for?

The bytecode will be used by create2 to deploy the fluidSwapV2Pair contract as create allows us to easily calculate the address to the contract before its deployed. The way it calculates is, it takes keccack256 hash of 

1. 0xff : 
2. deployer: Address of the deployer
3. salt::
4. creation bytecode

### Token Swapping

Swapping means giving some amount of token A for some in exchange for some amount of token B. To peform this kind of exchange we need a mediator for that:

1. Provide actual Exchange Rates
2. Guarantees that all exchanges are paid in full, i.e. all exchanges are made under correct rate.

When we were working on Liqudity Provision we learned that its the amount of liquidity that defines the rates in the exchange.


NOTE: Transfer and TransferFrom

There are two ways to perform token transfers:

1. By calling `transfer` method of the token contract and passing recipient’s address and the amount to be sent.
2. By calling approve method to allow the other user or contract to transfer some amount of your tokens to their address. The other party would have to call transferFrom to get your tokens. You pay only for approving a certain amount; the other party pays for the actual transfer.

### Price Oracle:

A price oracle is a serivce that provides reliable, real-world data (like the price of a cryptocurrency or other asset) and this can be queried by smartcontracts.

Uniswap is a decentralized application that is running onchain. Usually its used for excahnging tokens but it can also be used as a `price oracle`. 


# Output Amount Calculation:

In constant product exchange price is simply a relation between reserves.

Lets take a look at constant product formula:

           x*y = k

Where x and y are pair reserves (reserve0) and (reserve1). When doing a swap, x and y are changed but k remains the same (or it grows slowly thanks to swap fees). 

We can write the above formula as:

(x+r*deltax)(y-delaty) = xy

Where r is 1-swapfee , (1-0.3=0.997) delta x is the amount we give in to get deltay the amount we get.

After doing the algebraic calcs we get:

    deltay = y*r*deltax/x+r*deltax


### FlashLoan 

Flashloan is an unlimited and uncollaterlaizes loan the needs to be paid in the same transaction where its taken. 

Flashloans can only be used by smart contracts. Here's how borrowing / repayinh happens in flash loans:

1. A smart contract borrows a flashloan from another contract
2. The lender contract sends token to the borrowing contract and calls a special function in the contract.
3. In the special function, the borrowing contract performs some operations with the loan and then transfers the loan back.
4. The lender contract ensures that the whole amount was paid back. In case when there are fees, it also ensures that they were paid.
5. Control flow returns to the borrowing contract.


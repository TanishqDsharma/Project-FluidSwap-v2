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
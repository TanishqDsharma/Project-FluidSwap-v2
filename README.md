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



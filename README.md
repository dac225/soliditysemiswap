# Verkle Perkles HW 7

## How to Run:
1. Deploy Exchange contract with token contract address:
  * AsaToken (0x1A5Cf8a4611CA718B6F0218141aC0Bfa114AAf7D)
  * HawKoin (0x42cD7B2c632E3F589933275095566DE6d8c1bfa5)
  * KorthCoin (0x0B09AC43C6b788146fe0223159EcEa12b2EC6361)
2. Approve exchange contract address that gets deployed on respective token contract by calling the approve function
3. Provide liquidity

## Calling Functions

1. **provideLiquidity(uint _amountERC20Token)**

   - **Description**: This function allows a user to provide liquidity to the exchange by depositing both Ether and ERC20 tokens in a specific ratio. The user receives liquidity positions in return, which are proportionate to their contribution to the liquidity pool

   - **Usage**: Liquidity providers use this function to participate in the exchange and earn liquidity positions

   - **Returns**: The function returns a uint indicating the number of liquidity positions issued to the caller

2. **estimateEthToProvide(uint _amountERC20Token)**

   - **Description**: This function is used to estimate the amount of Ether required to provide a specific amount of ERC20 tokens while maintaining the current ratio in the exchange

   - **Usage**: Liquidity providers can use this function to plan their contributions to the pool

   - **Returns**: The function returns a uint representing the amount of Ether needed to maintain the desired ratio in the contract

3. **estimateERC20TokenToProvide(uint _amountEth)**

   - **Description**: Similar to estimateEthToProvide, this function estimates the amount of ERC20 tokens required to provide a specific amount of Ether while maintaining the current ratio

   - **Usage**: Liquidity providers use this function to plan their contributions to the pool when providing Ether

   - **Returns**: The function returns a uint representing the amount of ERC20 tokens needed to maintain the desired ratio in the contract

4. **getMyLiquidityPositions()**

   - **Description**: This function allows users to check the number of liquidity positions associated with their address

   - **Usage**: Liquidity providers can use this function to view their current liquidity positions

   - **Returns**: The function returns a uint representing the number of liquidity positions owned by the caller

5. **withdrawLiquidity(uint _liquidityPositionsToBurn)**

   - **Description**: Liquidity providers can use this function to withdraw a portion of their liquidity by burning a specified number of liquidity positions. In return, they receive Ether and ERC20 tokens based on the withdrawn positions

   - **Usage**: Liquidity providers use this function to reduce their participation in the pool and receive their share of Ether and ERC20 tokens

   - **Returns**: The function returns two uint values - the amount of ERC20 tokens sent and the amount of Ether sent to the caller

6. **swapForEth(uint _amountERC20Token)**

   - **Description**: This function enables users to swap a specified amount of ERC20 tokens for Ether in the exchange. It calculates the amount of Ether based on the current pool ratio and returns the calculated Ether

   - **Usage**: Users use this function to exchange ERC20 tokens for Ether

   - **Returns**: The function returns a uint representing the amount of Ether received by the caller

7. **estimateSwapForEth(uint _amountERC20Token)**

   - **Description**: Similar to estimateEthToProvide, this function estimates the amount of Ether a user would receive when swapping a specified amount of ERC20 tokens for Ether

   - **Usage**: Users use this function to predict the amount of Ether they would receive before performing the swap

   - **Returns**: The function returns a uint representing the amount of Ether that the caller would receive

8. **swapForERC20Token()**

   - **Description**: This function allows users to swap a specified amount of Ether for ERC20 tokens in the exchange. It calculates the amount of ERC20 tokens based on the current pool ratio and returns the calculated tokens

   - **Usage**: Users use this function to exchange Ether for ERC20 tokens

   - **Returns**: The function returns a uint representing the amount of ERC20 tokens received by the caller

9. **estimateSwapForERC20Token(uint _amountEth)**

   - **Description**: Similar to estimateSwapForEth, this function estimates the amount of ERC20 tokens a user would receive when swapping a specified amount of Ether for ERC20 tokens

   - **Usage**: Users use this function to predict the amount of ERC20 tokens they would receive before performing the swap

   - **Returns**: The function returns a uint representing the amount of ERC20 tokens that the caller would receive

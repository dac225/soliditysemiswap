// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./KorthCoin.sol";
import "./AsaToken.sol";
import "./HawKoin.sol";

contract Exchange {
    
    ERC20 public erc20Token; 
    uint256 public totalLiquidityPositions;
    uint256 public K; // Constant product
    mapping(address => uint) public liquidityPositions;

    // Testing Events
    event ReceivedEther(uint balanceRec, uint newK);

    // Exchange Log Events
    event LiquidityProvided(address provider, uint256 amountERC20TokenDeposited, uint256 amountEthDeposited, uint256 liquidityPositionsIssued);
    event LiquidityWithdrew(uint256 amountERC20TokenWithdrew, uint256 amountEthWithdrew, uint256 liquidityPositionsBurned);
    event SwapForEth(uint256 amountERC20TokenDeposited, uint256 amountEthWithdrew);
    event SwapForERC20Token(uint256 amountERC20TokenWithdrew, uint256 amountEthDeposited);

    constructor(address _erc20Address) {
        // ERC-20 token used in the exchange will be determined by caller here
        erc20Token = ERC20(_erc20Address); 
    }

    /**
    * Initializing receive() function to allow smart contract to receive ETH
    */
    receive() external payable {
        // compute constant product K of the currently traded ERC-20 whenever the exchange recieves ETH
        K = address(this).balance * erc20Token.balanceOf(address(this));
        emit ReceivedEther(msg.value, K);
    }

    /**
    * Caller deposits Ether and ERC20 token in ratio equal to the current ratio of tokens in the 
    *   contract and receives liquidity positions 
    *   (that is: totalLiquidityPositions * amountERC20Token/contractERC20TokenBalance == totalLiquidityPositions *amountEth/contractEthBalance)
    * Param: uint _amountERC20Token being put invested to create liquidity 
    * Return: a uint of the amount of liquidity positions issued.
    */
    function provideLiquidity(uint256 _amountERC20Token) external payable returns (uint256 liquidity) {
        // ensure that the account interacting with the market is a payable account
        require(payable(msg.sender).send(0), "Only payable accounts can interact with the market");
        address payable trader = payable(msg.sender);

        // ensure that the trader is not offering 0 liquidity
        require(_amountERC20Token != 0 && msg.value != 0, "You must provide non-zero liquidity");

        // ensure that the ratios are equal
        require(_amountERC20Token / msg.value == erc20Token.balanceOf(address(this)) / (address(this).balance - msg.value), "Provided liquidity would alter token value. Please provide liquidity proportional to token price");

        // ensure that the sender has enough ERC-20 tokens to send
        require(_amountERC20Token <= erc20Token.balanceOf(trader), "You have insufficient funds to provide this amount of ERC-20 Tokens");

        // Transfer ERC20 tokens and ETH from the user to the contract
        require(erc20Token.transferFrom(trader, address(this), _amountERC20Token), "ERC20 transfer failed");

        // Calculate the balances provided
        uint256 contractEthBalance = address(this).balance; 
        uint256 contractERC20Balance = erc20Token.balanceOf(address(this));

        if (totalLiquidityPositions == 0) {
            // if first time it will start with 100 liquidity
            liquidity = 100; 
        } else {
            // Calculate liquidity based on the current pool ratio
            liquidity = totalLiquidityPositions * _amountERC20Token / contractERC20Balance;
        }

        // update liquidity
        liquidityPositions[trader] += liquidity;
        totalLiquidityPositions += liquidity;

        // Update constant K
        K = contractEthBalance * (contractERC20Balance + _amountERC20Token);

        // log the event
        emit LiquidityProvided(trader, _amountERC20Token, msg.value, liquidity); 

        return liquidity;
    }

    /**
    * Users who want to provide liquidity won’t know the current ratio of the tokens in the 
    *   contract so they’ll have to call this function to find out how much Ether to deposit 
    *   if they want to deposit a particular amount of ERC-20 tokens.
    * 
    * Param: uint _amountERC20Token to be converted to the equivalent amount of ETH
    * Return: uint of the amount of Ether to provide 
    *   to match the ratio in the contract if caller wants to provide a given amount of ERC20 tokens
    */
    function estimateEthToProvide(uint256 _amountERC20Token) external view returns (uint256 amountEth) {
        uint256 contractEthBalance = address(this).balance; 
        uint256 contractERC20TokenBalance = erc20Token.balanceOf(address(this));
        
        // Check if there's any ERC20 token balance in the contract to avoid division by zero
        if (contractERC20TokenBalance == 0) {
            return 0;
        }
        
        // Calculate the amount of Ether required to match the current ratio in the contract
        amountEth = contractEthBalance * _amountERC20Token / contractERC20TokenBalance;
        return amountEth;
    }

    /**
    * Users who want to provide liquidity won’t know the current ratio of the tokens in the contract 
    *   so they’ll have to call this function to find out how much ERC-20 token to deposit if they want 
    *   to deposit an amount of Ether
    * 
    * Param: uint _amountEth to be converted to the equivalent amount of ERC-20 Token
    * Return: uint of the amount of ERC20 token to provide 
    *   to match the ratio in the contract if the caller wants to provide a given amount of Ether
    */
    function estimateERC20TokenToProvide(uint256 _amountEth) external view returns (uint256 amountERC20Token) {
        uint256 contractEthBalance = address(this).balance;
        uint256 contractERC20TokenBalance = erc20Token.balanceOf(address(this));
        
        // Check if there's any ERC20 token balance in the contract to avoid division by zero
        if (contractERC20TokenBalance == 0) {
            return 0;
        }
        
        // calculate the amount of erc 20 tokens to match current ratio in the contract
        amountERC20Token = contractERC20TokenBalance * (_amountEth/contractEthBalance);
        return amountERC20Token;
    }

    /**
    * Return: uint of the amount of the caller’s liquidity positions 
    *   (the uint associated to the address calling in your liquidityPositions mapping) 
    *   for when a user wishes to view their liquidity positions
    */
    function getMyLiquidityPositions() external view returns (uint256) {
        return liquidityPositions[msg.sender];
    }

    /**
    * Caller gives up some of their liquidity positions and receives some Ether and ERC20 tokens in return.
    *
    * Param: uint of the number of this caller's liquidity positions to burn in exchange for ETH and ERC-20 Tokens
    * Return: uint of number of ERC-20 Tokens sent
    */
    function withdrawLiquidity(uint256 _liquidityPositionsToBurn) external payable returns (uint256 amountEthToSend, uint amountERC20ToSend){
        // ensure that the account interacting with the market is a payable account
        require(payable(msg.sender).send(0), "Only payable accounts can interact with the market");
        address payable trader = payable(msg.sender);
        
        // get the contract ETH and ERC-20 balances
        uint256 contractEthBalance = address(this).balance;
        uint256 contractERC20Balance = erc20Token.balanceOf(address(this));
        
        // make sure we have enough liquidity to burn (i.e. _liquidityPositionsToBurn <= liquidityPositions[caller]
        require(_liquidityPositionsToBurn <= liquidityPositions[trader], "Cannot withdraw more liquidity than deposited");
        
        // decrement the caller's liquidity positions and the total liquidity positions
        liquidityPositions[trader] = liquidityPositions[trader] - _liquidityPositionsToBurn;
        totalLiquidityPositions -= _liquidityPositionsToBurn;
        
        // Determine how many Eth and ERC-20 tokens to be given to the trader
        amountEthToSend = _liquidityPositionsToBurn * contractEthBalance / totalLiquidityPositions;
        amountERC20ToSend = _liquidityPositionsToBurn * contractERC20Balance / totalLiquidityPositions;
        
        // Transfer Eth and ERC-20 tokens from contract to caller
        require(amountERC20ToSend < contractERC20Balance, "Insufficient ERC20 Funds in liquidity pool for withdrawal");
        require(amountEthToSend < contractEthBalance, "Insufficient ETH Funds in liquidity pool for withdrawal");
        require(erc20Token.transfer(trader, amountERC20ToSend), "ERC20 transfer failed");
        require(trader.send(amountEthToSend), "ETH transfer failed");

        // update K
        uint256 newContractEthBalance = address(this).balance;
        uint256 newContractERC20Balance = erc20Token.balanceOf(address(this));
        K = newContractEthBalance * newContractERC20Balance;

        // log the event
        emit LiquidityWithdrew(amountERC20ToSend, amountEthToSend, _liquidityPositionsToBurn);
        
        // Return both the amount of Eth sent and the amount of ERC-20 tokens sent
        return (amountEthToSend, amountERC20ToSend);
    }

    /**
    * Caller deposits some ERC20 token in return for some Ether
    *
    * Param: uint of the amount of ERC-20 Tokens that the caller would like to deposit for ETH
    * Return: uint of the amount of ETH sent in exchange for ERC-20 tokens
    */
    function swapForEth(uint256 _amountERC20Token) external payable returns (uint256 amountEthSent) {
        // ensure that the account interacting with the market is a payable account
        require(payable(msg.sender).send(0), "Only payable accounts can interact with the market");
        address payable trader = payable(msg.sender);

        // aquire contract ETH balance
        uint256 contractEthBalance = address(this).balance;

        // make sure that the caller has the amount of ERC-20 tokens
        require(_amountERC20Token <= erc20Token.balanceOf(trader), "Insufficient ERC-20 funds to swap");
        
        // Transfer ERC-20 Tokens from caller to contract
        require(erc20Token.transferFrom(trader, address(this), _amountERC20Token), "ERC20 transfer failed");
        
        // compute ERC-20 balance after swap
        uint256 contractERC20BalanceAfterSwap = erc20Token.balanceOf(address(this));

        // compute ETH to send to user in exchange for ERC-20 tokens    
        uint256 contractEthBalanceAfterSwap = K / contractERC20BalanceAfterSwap;
        amountEthSent = contractEthBalance - contractEthBalanceAfterSwap;
        
        // transfer ETH from contract to caller
        require(trader.send(amountEthSent), "ETH transfer failed");

        // log the event
        emit SwapForEth(_amountERC20Token, amountEthSent);

        // return amountEthSent
        return amountEthSent;
    }

    /**
    * Estimates the amount of Ether to give caller based on amount ERC20 token caller wishes to swap for 
    *   when a user wants to know how much Ether to expect when calling swapForEth
    * 
    * Param: uint of the amount of ERC-20 tokens to be approximately converted to equivalent ETH value
    * Return: uint of the estimated amount of ETH of equivalent value to the amount of ERC-20 tokens to be swapped
    */
    function estimateSwapForEth(uint256 _amountERC20Token) external view returns (uint256 ethEstimate) {
        uint256 contractEthBalance = address(this).balance;
        
        // compute ERC-20 balance after swap
        uint256 contractERC20BalanceAfterSwap = erc20Token.balanceOf(address(this)) + _amountERC20Token;

        // compute ETH estimate in exchange for ERC-20 tokens    
        uint256 contractEthBalanceAfterSwap = K / contractERC20BalanceAfterSwap;
        ethEstimate = contractEthBalance - contractEthBalanceAfterSwap;
        
        return ethEstimate;
    }

    /**
    * Caller deposits some ETH in return for some ERC-20 Token
    *
    * Return: uint of the amount of ERC-20 tokens sent in exchange for ETH
    */
    function swapForERC20Token() external payable returns (uint256 amountERC20Sent) {
        // ensure that the account interacting with the market is a payable account
        require(payable(msg.sender).send(0), "Only payable accounts can interact with the market");
        address payable trader = payable(msg.sender);
        
        // Transfer ETH from caller to contract (done automatically)

        // compute ERC-20 tokens to send in exchange for the ETH
        uint256 contractERC20Balance = erc20Token.balanceOf(address(this));
        uint256 contractERC20BalanceAfterSwap = K / address(this).balance;
        amountERC20Sent = contractERC20Balance - contractERC20BalanceAfterSwap;

        // Transfer ERC-20 tokens from contract to caller
        require(erc20Token.transfer(trader, amountERC20Sent), "ERC-20 transfer failed");

        // log the event
        emit SwapForERC20Token(amountERC20Sent, msg.value);

        return amountERC20Sent;
    }

    /**
    * Caller deposits some ETH in return for some ERC-20 Token
    *
    * Return: uint of the amount of ERC-20 tokens sent in exchange for ETH
    */
    function estimateSwapForERC20Token(uint256 _amountEth) external view returns (uint256 erc20Estimate) {

        // compute ERC-20 tokens to send in exchange for the ETH
        uint256 contractERC20Balance = erc20Token.balanceOf(address(this));
        uint256 contractERC20BalanceAfterSwap = K / (address(this).balance + _amountEth);
        erc20Estimate = contractERC20Balance - contractERC20BalanceAfterSwap;

        return erc20Estimate;   
    }    
}

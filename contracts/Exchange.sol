// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange {
    ERC20 public erc20Token;
    uint public totalLiquidityPositions;
    uint public K; // Constant product
    mapping(address => uint) public liquidityPositions;

    constructor(address _erc20Address) {
        erc20Token = ERC20(_erc20Address);
    }

    function provideLiquidity(uint _amountERC20Token) public payable returns (uint liquidity) {
        uint ethBalance = address(this).balance;
        uint erc20Balance = erc20Token.balanceOf(address(this));
        if (totalLiquidityPositions == 0) {
            liquidity = 100; // if first time it will start with 100 liquidity
        } else {
            // Calculate liquidity based on the current pool ratio
            liquidity = totalLiquidityPositions * _amountERC20Token / erc20Balance;
        }
        liquidityPositions[msg.sender] += liquidity;
        totalLiquidityPositions += liquidity;
        // Transfer ERC20 tokens from the user to the contract
        require(erc20Token.transferFrom(msg.sender, address(this), _amountERC20Token), "ERC20 transfer failed");
        K = ethBalance * (erc20Balance + _amountERC20Token);
        emit LiquidityProvided(msg.sender, _amountERC20Token, msg.value, liquidity); //will update the events in the log
        return liquidity;
    }

    function estimateEthToProvide(uint _amountERC20Token) public view returns (uint amountEth) {
        uint contractEthBalance = address(this).balance;
        uint contractERC20TokenBalance = erc20Token.balanceOf(address(this));
        // Check if there's any ERC20 token balance in the contract to avoid division by zero
        if (contractERC20TokenBalance == 0) {
            return 0;
        }
        // Calculate the amount of Ether required to match the current ratio in the contract
        amountEth = contractEthBalance * _amountERC20Token / contractERC20TokenBalance;
        return amountEth;
    }

    function estimateERC20TokenToProvide(uint _amountEth) public view returns (uint amountERC20Token) {
        uint contractEthBalance = address(this).balance;
        uint contractERC20TokenBalance = erc20Token.balanceOf(address(this));
        if (contractERC20TokenBalance == 0) {
            return 0;
        }
        // calculate the amount of erc 20 tokens to match current ratio in the contract
        amountERC20Token = contractERC20TokenBalance * (_amountEth/contractEthBalance);
        return amountERC20Token;
    }

    function getMyLiquidityPositions() external view returns (uint) {
        return liquidityPositions[msg.sender];
    }

    function withdrawLiquidity(uint _liquidityPositionsToBurn) public payable {
        // make sure user did not give 0 for liquidity positions
        // make sure we have enough liquidity to burn
    }

    //events
    event LiquidityProvided(address provider, uint amountERC20TokenDeposited, uint amountEthDeposited, uint liquidityPositionsIssued);
}

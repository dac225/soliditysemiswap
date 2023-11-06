// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange {
    ERC20 public erc20Token;
    uint public totalLiquidityPositions;
    uint public K; // Constant product
    mapping(address => uint) public liquidityPositions; // hash map of addresses to their liquidity positions

    constructor(address _erc20Address) {
        erc20Token = ERC20(_erc20Address);
    }

    // testing functions
    function getERC20Balance() external view returns (uint) {
        return erc20Token.balanceOf(address(this));
    }

    function getEtherBalance() external view returns (uint) {
        return address(this).balance;
    }

    // contract functions
    function provideLiquidity(uint _amountERC20Token) public payable returns (uint liquidity) {
        require(msg.value > 0, "Error: Must input greater than 0 Wei");
        require(_amountERC20Token > 0, "Error: Must input greater than 0 ERC20-Tokens");

        uint ethBalanceBefore = address(this).balance - msg.value;
        uint erc20BalanceBefore = erc20Token.balanceOf(address(this));

        // Transfer ERC20 tokens from the user to the contract
        bool sent = erc20Token.transferFrom(msg.sender, address(this), _amountERC20Token);
        require(sent, "Error: ERC20 transfer failed");

        if (totalLiquidityPositions == 0) {
            liquidity = 100; // if first time it will start with 100 liquidity
        } else {
            uint ethReserve = ethBalanceBefore;
            uint tokenReserve = erc20BalanceBefore;
            // calculate how many of the tokens and how many ether are actually needed to maintain the ratio
            uint tokenAmount = (msg.value * tokenReserve) / ethReserve;
            uint ethAmount = (tokenAmount * ethReserve) / tokenReserve;
            // send the unneeded tokens back to the user
            uint tokenDiff = _amountERC20Token - tokenAmount;
            uint etherDiff = msg.value - ethAmount;

            // return the unused tokens and ether 
            require(tokenDiff >= 0, "Error: Need more tokens than given to maintain Wei/ERC20 ratio");
            if (tokenDiff > 0) {
                bool sentDiff = erc20Token.transfer(msg.sender, tokenDiff);
                require(sentDiff, "Error: Token remainder transfer failed");
            }
            require(etherDiff >= 0, "Error: Need more ether than given to maintain Wei:ERC20 ratio");
            if (etherDiff > 0) {
                payable(msg.sender).transfer(etherDiff);
            }

            // Ensure that the ratio of ETH to ERC20 is maintained
            require(ethReserve * tokenAmount == ethAmount * tokenReserve, "Error: Must maintain Wei/ERC20 ratio");
            
            // Calculate liquidity based on the proportional amount of ETH deposited
            liquidity = totalLiquidityPositions * ethAmount / ethReserve;
        }
        liquidityPositions[msg.sender] += liquidity;
        totalLiquidityPositions += liquidity;

        // Update K after liquidity is added, based on the new balances
        K = (ethBalanceBefore + msg.value) * (erc20BalanceBefore + _amountERC20Token);

        emit LiquidityProvided(msg.sender, _amountERC20Token, msg.value, liquidity); //will update the events in the log
        return liquidity;
    }

    function estimateEthToProvide(uint _amountERC20Token) public view returns (uint amountEth) {
        require(_amountERC20Token > 0, "Error: ERC20 token must be greater than 0.");
        uint contractEthBalance = address(this).balance;
        uint contractERC20TokenBalance = erc20Token.balanceOf(address(this));
        // Check if there's any ERC20 token balance in the contract to avoid division by zero
        if (contractERC20TokenBalance == 0) {
            return 0;
        }
        // Calculate the amount of Ether required to maintain the current ratio
        amountEth = contractEthBalance * _amountERC20Token / contractERC20TokenBalance;
        return amountEth;
    }

    function estimateERC20TokenToProvide(uint _amountEth) public view returns (uint amountERC20Token) {
        require(_amountEth > 0, "Error: Wei must be greater than 0.");
        uint contractEthBalance = address(this).balance;
        uint contractERC20TokenBalance = erc20Token.balanceOf(address(this));
        if (contractEthBalance == 0) {
            return 0;
        }
        // Calculate the amount of ERC20 tokens required to maintain the current ratio
        amountERC20Token = contractERC20TokenBalance * _amountEth / contractEthBalance;
        return amountERC20Token;
    }


    function getMyLiquidityPositions() external view returns (uint) {
        return liquidityPositions[msg.sender];
    }

    function withdrawLiquidity(uint _liquidityPositionsToBurn) public {
        require(_liquidityPositionsToBurn > 0, "Error: Cannot burn zero liquidity positions");
        require(liquidityPositions[msg.sender] >= _liquidityPositionsToBurn, "Error: Not enough liquidity positions to burn");

        uint contractEthBalance = address(this).balance;
        uint contractERC20TokenBalance = erc20Token.balanceOf(address(this));

        uint amountEthToSend = _liquidityPositionsToBurn * contractEthBalance / totalLiquidityPositions;
        uint amountERC20ToSend = _liquidityPositionsToBurn * contractERC20TokenBalance / totalLiquidityPositions;

        liquidityPositions[msg.sender] -= _liquidityPositionsToBurn;
        totalLiquidityPositions -= _liquidityPositionsToBurn;

        // Using transfer for ETH to send to the user
        payable(msg.sender).transfer(amountEthToSend);

        // ERC20 transfer to the user
        require(erc20Token.transfer(msg.sender, amountERC20ToSend), "Error: Failed to send ERC20 tokens");

        // Update the K value after liquidity is removed
        K = (contractEthBalance - amountEthToSend) * (contractERC20TokenBalance - amountERC20ToSend);

        // Emitting the event with the amount of ERC20 tokens and Ether sent, and liquidity positions burned
        emit LiquidityWithdrew(amountERC20ToSend, amountEthToSend, _liquidityPositionsToBurn);
    }

    function swapForEth(uint _amountERC20Token) public returns (uint ethToSend) {
        uint contractEthBalance = address(this).balance;
        uint contractERC20TokenBalance = erc20Token.balanceOf(address(this));

        require(_amountERC20Token > 0, "Error: Must input more than 0 ERC20 Token.");
        require(contractERC20TokenBalance > 0, "Error: Insufficient liquidity.");
        
        // Transfer ERC20 tokens from the user to the contract
        require(erc20Token.transferFrom(msg.sender, address(this), _amountERC20Token), "Error: ERC20 transfer failed");

        // Calculate contractEthBalanceAfterSwap using the constant product formula
        uint contractERC20TokenBalanceAfterSwap = contractERC20TokenBalance + _amountERC20Token;
        uint contractEthBalanceAfterSwap = K / contractERC20TokenBalanceAfterSwap;
        ethToSend = contractEthBalance - contractEthBalanceAfterSwap;

        // Checks to prevent swaps that would result in no ETH sent to the user
        require(ethToSend > 0 && ethToSend <= contractEthBalance, "Error: Invalid swap request");

        // Send ETH to the user
        payable(msg.sender).transfer(ethToSend);

        // Emit the event
        emit SwapForEth(_amountERC20Token, ethToSend);

        return ethToSend;
    }

    function estimateSwapForEth(uint _amountERC20Token) public view returns (uint ethToSend) {
        require(_amountERC20Token > 0, "Error: Must input more than 0 ERC20 Token.");
        
        uint contractEthBalance = address(this).balance;
        uint contractERC20TokenBalance = erc20Token.balanceOf(address(this));
        require(contractERC20TokenBalance > 0, "Error: Insufficient liquidity.");

        // Calculate contractEthBalanceAfterSwap using the constant product formula
        uint contractERC20TokenBalanceAfterSwap = contractERC20TokenBalance + _amountERC20Token;
        uint contractEthBalanceAfterSwap = K / contractERC20TokenBalanceAfterSwap;
        ethToSend = contractEthBalance - contractEthBalanceAfterSwap;

        // Checks to ensure the estimation doesn't suggest a swap that would result in no ETH sent
        require(ethToSend > 0 && ethToSend <= contractEthBalance, "Error: Invalid swap estimate");

        return ethToSend;
    }

    function swapForERC20Token() public payable returns (uint ERC20TokenToSend) {
        require(msg.value > 0, "Error: Must deposit more than 0 Wei.");
        uint contractEthBalanceBefore = address(this).balance - msg.value;
        uint contractERC20TokenBalance = erc20Token.balanceOf(address(this));
        uint contractERC20TokenBalanceAfterSwap = K / (contractEthBalanceBefore + msg.value);
        ERC20TokenToSend = contractERC20TokenBalance - contractERC20TokenBalanceAfterSwap;

        // Transfer ERC20 tokens from the contract to the caller
        require(erc20Token.transfer(msg.sender, ERC20TokenToSend), "Error: Failed to send ERC20 tokens");

        // Emit the event
        emit SwapForERC20Token(ERC20TokenToSend, msg.value);

        return ERC20TokenToSend;
    }

    function estimateSwapForERC20Token(uint _amountEth) public view returns (uint ERC20TokenToSend) {
        require(_amountEth > 0, "Error: ETH amount must be greater than 0.");
        uint contractEthBalance = address(this).balance;
        uint contractERC20TokenBalance = erc20Token.balanceOf(address(this));
        uint contractERC20TokenBalanceAfterSwap = K / (contractEthBalance + _amountEth);
        ERC20TokenToSend = contractERC20TokenBalance - contractERC20TokenBalanceAfterSwap;

        return ERC20TokenToSend;
    }

    //events
    event LiquidityProvided(address provider, uint amountERC20TokenDeposited, uint amountEthDeposited, uint liquidityPositionsIssued);
    event LiquidityWithdrew(uint amountERC20TokenWithdrew, uint amountEthWithdrew, uint liquidityPositionsBurned);
    event SwapForEth(uint amountERC20TokenDeposited, uint amountEthWithdrew);
    event SwapForERC20Token(uint amountERC20TokenWithdrew, uint amountEthDeposited);
}

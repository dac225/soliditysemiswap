// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
/// @notice Token with faucet for grading purposes only
contract KorthCoin is ERC20 {
constructor() ERC20("KorthCoin", "KOR") {
_mint(msg.sender, 99999*1e18);
}
/// @notice In case anyone runs out of tokens.
/// @dev Normally never do this, but it is fine for a class project.
function mintMe(uint256 amount) external {
_mint(msg.sender, amount*1e18);

}
}

// 0x0B09AC43C6b788146fe0223159EcEa12b2EC6361
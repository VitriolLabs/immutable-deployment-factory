// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CREATE3} from "solady/src/utils/CREATE3.sol";
import {IImmutableDeploymentFactory} from "./interfaces/IImmutableDeploymentFactory.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title Immutable Deployment Factory.
 * @author slvrfn
 * @notice A factory to deterministically deploy immutable smart contracts. Contracts
 * deployed with this factory are immutable, and cannot be re-written. Salts used for
 * deployment can optionally include the caller's address to prevent front-running.
 * @notice Adapted from https://github.com/0age/metamorphic/blob/master/contracts/ImmutableCreate2Factory.sol
 */
contract ImmutableDeploymentFactory is IImmutableDeploymentFactory {
    // mapping to track which addresses have already been deployed.
    mapping(address => bool) public deployed;

    /**
     * @dev Raised when an invalid salt is provided.
     */
    error InvalidSalt();

    /**
     * @dev Raised when a user tries to deploy a contract to a previously consumed address.
     */
    error AlreadyDeployed();

    /**
     * @dev Raised when deployment failed using provided salt and initialization code
     */
    error DeploymentFailed();

    /**
     * @dev Modifier to ensure that the first 20 bytes of a submitted salt match
     * those of the calling account. This provides protection against the salt
     * being stolen by frontrunners or other attackers. The protection can also be
     * bypassed if desired by setting each of the first 20 bytes to zero.
     * @param salt bytes32 The salt value to check against the calling address.
     */
    modifier containsCaller(bytes32 salt) {
        // prevent contract submissions from being stolen from tx.pool by requiring
        // that the first 20 bytes of the submitted salt match msg.sender.
        // OR
        // the first 20 bytes are 0's
        if ((address(bytes20(salt)) != msg.sender) && (bytes20(salt) != bytes20(0))) {
            revert InvalidSalt();
        }
        _;
    }

    //region CREATE2

    /**
     * @dev Create a contract using CREATE2 by submitting a given salt or nonce
     * along with the initialization code for the contract. Note that the first 20
     * bytes of the salt must match those of the calling address, which prevents
     * contract creation events from being submitted by unintended parties.
     * @param salt bytes32 The nonce that will be passed into the CREATE2 call.
     * @param initializationCode bytes The initialization code that will be passed
     * into the CREATE2 call.
     * @return deploymentAddress Address of the contract that will be created, or the null address
     * if a contract already exists at that address.
     */
    function safeCreate2(bytes32 salt, bytes calldata initializationCode) external payable containsCaller(salt) returns (address deploymentAddress) {
        // move the initialization code from calldata to memory.
        bytes memory initCode = initializationCode;

        // determine the target address for contract deployment.
        address targetDeploymentAddress = _create2DeploymentAddress(salt, keccak256(abi.encodePacked(initCode)));

        // ensure that a contract hasn't been previously deployed to target address.
        if (deployed[targetDeploymentAddress]) {
            revert AlreadyDeployed();
        }

        // using inline assembly: load data and length of data, then call CREATE2.
        assembly {
            // solhint-disable-line
            let encoded_data := add(0x20, initCode) // load initialization code.
            let encoded_size := mload(initCode) // load the init code's length.
            deploymentAddress := create2(
                // call CREATE2 with 4 arguments.
                callvalue(), // forward any attached value.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )
        }

        // check address against target to ensure that deployment was successful.
        if (deploymentAddress != targetDeploymentAddress) {
            revert DeploymentFailed();
        }

        // record the deployment of the contract to prevent redeploys.
        deployed[deploymentAddress] = true;
    }

    /**
     * @dev Compute the address of the contract that will be created when
     * submitting a given salt or nonce to the contract along with the contract's
     * initialization code. The CREATE2 address is computed in accordance with
     * EIP-1014, and adheres to the formula therein of
     * `keccak256( 0xff ++ address ++ salt ++ keccak256(init_code)))[12:]` when
     * performing the computation. The computed address is then checked for any
     * existing contract code - if so, the null address will be returned instead.
     * @param salt bytes32 The nonce passed into the CREATE2 address calculation.
     * @param initCode bytes The contract initialization code to be used.
     * that will be passed into the CREATE2 address calculation.
     * @return deploymentAddress Address of the contract that will be created, or the null address
     * if a contract has already been deployed to that address.
     */
    function findCreate2Address(bytes32 salt, bytes calldata initCode) external view returns (address deploymentAddress) {
        // determine the address where the contract will be deployed.
        // pass in the hash of initialization code.
        deploymentAddress = _create2DeploymentAddress(salt, keccak256(abi.encodePacked(initCode)));

        // return null address to signify failure if contract has been deployed.
        if (deployed[deploymentAddress]) {
            return address(0);
        }
    }

    /**
     * @dev Compute the address of the contract that will be created when
     * submitting a given salt or nonce to the contract along with the keccak256
     * hash of the contract's initialization code. The CREATE2 address is computed
     * in accordance with EIP-1014, and adheres to the formula therein of
     * `keccak256( 0xff ++ address ++ salt ++ keccak256(init_code)))[12:]` when
     * performing the computation. The computed address is then checked for any
     * existing contract code - if so, the null address will be returned instead.
     * @param salt bytes32 The nonce passed into the CREATE2 address calculation.
     * @param initCodeHash bytes32 The keccak256 hash of the initialization code
     * that will be passed into the CREATE2 address calculation.
     * @return deploymentAddress Address of the contract that will be created, or the null address
     * if a contract has already been deployed to that address.
     */
    function findCreate2AddressViaHash(bytes32 salt, bytes32 initCodeHash) external view returns (address deploymentAddress) {
        // determine the address where the contract will be deployed.
        deploymentAddress = _create2DeploymentAddress(salt, initCodeHash);

        // return null address to signify failure if contract has been deployed.
        if (deployed[deploymentAddress]) {
            return address(0);
        }
    }

    function _create2DeploymentAddress(bytes32 salt, bytes32 initCodeHash) internal view returns (address) {
        // determine the target address for contract deployment.
        return
            address(
                uint160( // downcast to match the address type.
                    uint256( // convert to uint to truncate upper digits.
                        keccak256( // compute the CREATE2 hash using 4 inputs.
                            abi.encodePacked( // pack all inputs to the hash together.
                                    hex"ff", // start with 0xff to distinguish from RLP.
                                    address(this), // this contract will be the caller.
                                    salt, // pass in the supplied salt value.
                                    initCodeHash // pass in the hash of initialization code.
                                )
                        )
                    )
                )
            );
    }

    //endregion CREATE2

    //region CREATE3

    /**
     * @dev Create a contract using CRREATE3 (CREATE2 + CREATE) by submitting a given salt.
     * Note that the first 20 bytes of the salt must either: match those of the calling address,
     * or be all 0's. This (optionally)prevents contract creation events from being submitted by
     * unintended parties.
     * @param salt bytes32 The nonce that will be passed into the CREATE2 call.
     * @param initializationCode bytes The initialization code of the contract to be completed.
     * @return deploymentAddress Address of the contract that will be created, or the null address
     * if a contract already exists at that address.
     */
    function safeCreate3(bytes32 salt, bytes calldata initializationCode) external payable containsCaller(salt) returns (address deploymentAddress) {
        // determine the target address for contract deployment.
        address targetDeploymentAddress = _create3DeploymentAddress(salt);

        // ensure that a contract hasn't been previously deployed to target address.
        if (deployed[targetDeploymentAddress]) {
            revert AlreadyDeployed();
        }

        // perform the create3 deployment
        deploymentAddress = CREATE3.deploy(salt, initializationCode, msg.value);

        // check address against target to ensure that deployment was successful.
        if (deploymentAddress != targetDeploymentAddress) {
            revert DeploymentFailed();
        }

        // record the deployment of the contract to prevent redeploys.
        deployed[deploymentAddress] = true;
    }

    /**
     * @dev Compute the address of the contract that will be created when
     * submitting a given salt. The CREATE3 address is computed by combining
     * both CREATE2 & CREATE methods: `keccak256(0xd6 ++ 0x94 ++ create2Address(salt, CREATE_CALLER_PROXY_HASH) ++ 0x01)[12:]`
     * when performing the computation. The computed address is then checked for any
     * existing contract code - if so, the null address will be returned instead.
     * @param salt bytes32 The nonce passed into the CREATE3 address calculation.
     * @return deploymentAddress Address of the contract that will be created, or the null address
     * if a contract has already been deployed to that address.
     */
    function findCreate3Address(bytes32 salt) external view returns (address deploymentAddress) {
        // determine the address where the contract will be deployed.
        // pass in the hash of initialization code.
        deploymentAddress = _create3DeploymentAddress(salt);

        // return null address to signify failure if contract has been deployed.
        if (deployed[deploymentAddress]) {
            return address(0);
        }
    }

    function _create3DeploymentAddress(bytes32 _salt) internal view returns (address) {
        /// @dev Hash of the `_PROXY_BYTECODE`.
        address proxy = _create2DeploymentAddress(_salt, bytes32(0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f));

        return address(uint160(uint256(keccak256(abi.encodePacked(hex"d6_94", proxy, hex"01")))));
    }

    //endregion CREATE3
}

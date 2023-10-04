// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";
import "src/factory/AdminLessERC1967Factory.sol";
import "src/factory/KernelFactory.sol";
import "src/Kernel.sol";
import "src/validator/ECDSAValidator.sol";
import "src/validator/UniversalSigValidator.sol";
// test artifacts
import "src/test/TestValidator.sol";
import "src/test/TestERC721.sol";
import "src/test/TestKernel.sol";
// test utils
import "forge-std/Test.sol";
import {ERC4337Utils, KernelTestBase} from "./utils/ERC4337Utils.sol";

using ERC4337Utils for EntryPoint;

contract KernelTest is KernelTestBase {
    bytes32 private constant ERC6492_DETECTION_SUFFIX =
        0x6492649264926492649264926492649264926492649264926492649264926492;

    function setUp() public {
        _initialize();
        defaultValidator = new ECDSAValidator();
        _setAddress();
    }

    function test_validate_signature_erc6492() external {
        bytes memory factoryCalldata = abi.encodeWithSelector(
            KernelFactory.createAccount.selector,
            address(kernelImpl),
            abi.encodeWithSelector(
                KernelStorage.initialize.selector,
                defaultValidator,
                abi.encodePacked(owner)
            ),
            3
        );

        address proxy = factory.getAccountAddress(
            abi.encodeWithSelector(
                KernelStorage.initialize.selector,
                defaultValidator,
                abi.encodePacked(owner)
            ),
            3
        );

        bytes32 hash = keccak256(abi.encodePacked("hello world"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, hash);

        bytes memory signature_1271 = abi.encodePacked(r, s, v);

        bytes memory signature = abi.encode(
            address(factory),
            factoryCalldata,
            signature_1271
        );
        bytes memory signature_6492 = abi.encodePacked(
            signature,
            ERC6492_DETECTION_SUFFIX
        );

        ValidateSigOffchain signatureValidator = new ValidateSigOffchain(
            proxy,
            hash,
            signature_6492
        );
    }

    function test_validate_signature_erc1271() external {

        address proxy = factory.createAccount(
            address(kernelImpl),
            abi.encodeWithSelector(
                KernelStorage.initialize.selector,
                defaultValidator,
                abi.encodePacked(owner)
            ),
            3
        );

        bytes32 hash = keccak256(abi.encodePacked("hello world"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, hash);

        bytes memory signature_1271 = abi.encodePacked(r, s, v);


        ValidateSigOffchain signatureValidator = new ValidateSigOffchain(
            proxy,
            hash,
            signature_1271
        );
    }

}

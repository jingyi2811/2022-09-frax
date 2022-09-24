// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { frxETH } from "../src/frxETH.sol";
import { sfrxETH, ERC20 } from "../src/sfrxETH.sol";
import { frxETHMinter } from "../src/frxETHMinter.sol";
import { SigUtils } from "../src/Utils/SigUtils.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";

contract init is Test {
    sfrxETH sfrxETHtoken;
    frxETH frxETHtoken;
    frxETHMinter frxETHMinterContract;
    SigUtils internal sigUtils_frxETH;
    SigUtils internal sigUtils_sfrxETH;

    // For EIP-712 testing
    // https://book.getfoundry.sh/tutorials/testing-eip712
    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;
    address payable internal owner;
    address internal spender;
    bytes internal WITHDRAWAL_CREDENTIALS;

    address fraxComptroller = 0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27;
    address fraxTimelock = 0x8412ebf45bAC1B340BbE8F318b928C466c4E39CA;

    function setUp() public {
        vm.warp(0);
        frxETHtoken = new frxETH(
            fraxComptroller, // Creator address
            fraxTimelock // Timelock address
        );

        owner = payable(vm.addr(0xA11CE));
    }

    function test(uint256 fuzz_amount) public {
        vm.prank(fraxComptroller);
        frxETHtoken.addMinter(owner);

        vm.prank(owner);
        frxETHtoken.minter_mint(owner, 1);
//        frxETHtoken.approve(address(owner), 1);
//        frxETHtoken.minter_burn_from(owner, 1);
//
//        vm.prank(fraxComptroller);
//        frxETHtoken.removeMinter(owner);
    }
}
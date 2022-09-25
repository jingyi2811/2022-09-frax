// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// import { DSTestPlus } from "solmate/test/utils/DSTestPlus.sol";
import { Test } from "forge-std/Test.sol";
import { frxETH } from "../src/frxETH.sol";
import { sfrxETH, ERC20 } from "../src/sfrxETH.sol";
import { frxETHMinter } from "../src/frxETHMinter.sol";
import { SigUtils } from "../src/Utils/SigUtils.sol";

contract signature is Test {
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
    address frxETHMinterEOA = 0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27; // Placeholder, == timelock
    address depositContract = 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b;


    function setUp() public {
        vm.warp(0); // Fuzz fails without!!

        // Set the withdrawal credentials (must be done at compile time due to .env loading)
        WITHDRAWAL_CREDENTIALS = vm.envBytes("VALIDATOR_TEST_WITHDRAWAL_CREDENTIALS0");

        // Deploy frxETH, sfrxETH
        frxETHtoken = new frxETH(fraxComptroller, fraxTimelock);
        sfrxETHtoken = new sfrxETH(ERC20(address(frxETHtoken)), 1000);
        frxETHMinterContract = new frxETHMinter(depositContract, address(frxETHtoken), address(sfrxETHtoken), fraxComptroller, fraxTimelock, WITHDRAWAL_CREDENTIALS);

        // Add the FRAX comptroller as an EOA/Multisig frxETH minter
        vm.prank(fraxComptroller);
        frxETHtoken.addMinter(frxETHMinterEOA);

        // Add the frxETHMinter contract as another frxETH minter
        vm.prank(fraxComptroller);
        frxETHtoken.addMinter(address(frxETHMinterContract));

        // For EIP-712 testing
        sigUtils_frxETH = new SigUtils(frxETHtoken.DOMAIN_SEPARATOR());
        sigUtils_sfrxETH = new SigUtils(sfrxETHtoken.DOMAIN_SEPARATOR());
        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;
        owner = payable(vm.addr(ownerPrivateKey));
        spender = payable(vm.addr(spenderPrivateKey));

        //emit log_timestamp(block.timestamp);

    }
    event log_timestamp(uint256);

    function getQuickfrxETH() public {
        // Mint an initial test amount of frxETH to the owner
        vm.prank(fraxComptroller);
        frxETHtoken.minter_mint(owner, 1 ether); // 1 frxETH
        assertEq(frxETHtoken.balanceOf(owner), 1 ether);
    }

    function test_signature(uint256 fuzz_amount) public {
        uint256 transfer_amount = fuzz_amount % (1 ether); // Restrict the fuzz amount to 1 ether and under
        getQuickfrxETH();

        SigUtils.Permit memory permit = SigUtils.Permit({
        owner: owner,
        spender: address(sfrxETHtoken),
        value: transfer_amount,
        nonce: frxETHtoken.nonces(owner),
        deadline: 1 days
        });

        bytes32 digest = sigUtils_frxETH.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        vm.prank(owner);
        if (transfer_amount == 0) vm.expectRevert("ZERO_SHARES");
        sfrxETHtoken.depositWithSignature(
            transfer_amount,
            permit.owner,
            permit.deadline,
            false,
            v,
            r,
            s
        );

        assertEq(frxETHtoken.balanceOf(owner), 1 ether - transfer_amount);
        assertEq(frxETHtoken.balanceOf(address(sfrxETHtoken)), transfer_amount);

        assertEq(frxETHtoken.allowance(owner, address(sfrxETHtoken)), 0);
        if (transfer_amount != 0) assertEq(frxETHtoken.nonces(owner), 1);

        assertEq(sfrxETHtoken.balanceOf(owner), transfer_amount);
    }
}
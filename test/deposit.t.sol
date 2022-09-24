// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { DepositContract } from "../src/DepositContract.sol";
import { frxETHMinter, OperatorRegistry } from "../src/frxETHMinter.sol";
import { frxETH } from "../src/frxETH.sol";
import { sfrxETH, ERC20 } from "../src/sfrxETH.sol";

contract deposit is Test {
    frxETH frxETHToken;
    sfrxETH sfrxETHToken;
    frxETHMinter minter;

    address constant DEPOSIT_CONTRACT_ADDRESS = 0x00000000219ab540356cBB839Cbe05303d7705Fa;
    address constant FRAX_COMPTROLLER = 0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27;
    address constant FRAX_TIMELOCK = 0x8412ebf45bAC1B340BbE8F318b928C466c4E39CA;
    bytes[5] pubKeys;
    bytes[5] sigs;
    bytes32[5] ddRoots;
    bytes[5] withdrawalCreds;

    uint32 constant REWARDS_CYCLE_LENGTH = 1000;
    DepositContract depositContract;
    bytes internal WITHDRAWAL_CREDENTIALS;

    function setUp() public {
        // Make sure you are forking mainnet first
        require(block.chainid == 1, 'Need to fork ETH mainnet for this test');

        // Set some .env variables
        // Must be done at compile time due to .env loading)
        pubKeys = [vm.envBytes("VALIDATOR_TEST_PUBKEY1"), vm.envBytes("VALIDATOR_TEST_PUBKEY2"), vm.envBytes("VALIDATOR_TEST_PUBKEY3"), vm.envBytes("VALIDATOR_TEST_PUBKEY4"), vm.envBytes("VALIDATOR_TEST_PUBKEY5")];
        sigs = [vm.envBytes("VALIDATOR_TEST_SIG1"), vm.envBytes("VALIDATOR_TEST_SIG2"), vm.envBytes("VALIDATOR_TEST_SIG3"), vm.envBytes("VALIDATOR_TEST_SIG4"), vm.envBytes("VALIDATOR_TEST_SIG5")];
        ddRoots = [vm.envBytes32("VALIDATOR_TEST_DDROOT1"), vm.envBytes32("VALIDATOR_TEST_DDROOT2"), vm.envBytes32("VALIDATOR_TEST_DDROOT3"), vm.envBytes32("VALIDATOR_TEST_DDROOT4"), vm.envBytes32("VALIDATOR_TEST_DDROOT5")];
        withdrawalCreds = [vm.envBytes("VALIDATOR_TEST_WITHDRAWAL_CREDENTIALS1"), vm.envBytes("VALIDATOR_TEST_WITHDRAWAL_CREDENTIALS2"), vm.envBytes("VALIDATOR_TEST_WITHDRAWAL_CREDENTIALS3"), vm.envBytes("VALIDATOR_TEST_WITHDRAWAL_CREDENTIALS4"), vm.envBytes("VALIDATOR_TEST_WITHDRAWAL_CREDENTIALS5")];

        // Instantiate the new contracts
        frxETHToken = new frxETH(FRAX_COMPTROLLER, FRAX_TIMELOCK);
        sfrxETHToken = new sfrxETH(ERC20(address(frxETHToken)), REWARDS_CYCLE_LENGTH);
        minter = new frxETHMinter(DEPOSIT_CONTRACT_ADDRESS, address(frxETHToken), address(sfrxETHToken), FRAX_COMPTROLLER, FRAX_TIMELOCK, withdrawalCreds[1]);

        // Add the new frxETHMinter as a minter for frxETH
        vm.startPrank(FRAX_COMPTROLLER);
        frxETHToken.addMinter(address(minter));
        vm.stopPrank();

        depositContract = new DepositContract();
    }

    function testBatchAdd() public {
        vm.startPrank(FRAX_COMPTROLLER);

        // Add two validators to an array
        OperatorRegistry.Validator[] memory validators = new OperatorRegistry.Validator[](2);
        validators[0] = (OperatorRegistry.Validator(pubKeys[0], sigs[0], ddRoots[0]));
        validators[1] = (OperatorRegistry.Validator(pubKeys[1], sigs[1], ddRoots[1]));

        vm.stopPrank();

       // WITHDRAWAL_CREDENTIALS = vm.envBytes("VALIDATOR_TEST_WITHDRAWAL_CREDENTIALS0");
       // depositContract.deposit{ value: 1 ether }(pubKeys[0], WITHDRAWAL_CREDENTIALS, sigs[0], ddRoots[0]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ds-test/test.sol";
import "../NightmareDollar.sol";

interface CheatCodes {
    function expectRevert(bytes calldata) external;

    function prank(address) external;
}

contract NightmareDollarTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    NightmareDollar nightmareDollar;

    address FAVORED_SENDER_ADDRESS = address(1);
    address DISFAVORED_SENDER_ADDRESS = address(2);
    address FAVORED_RECIPIENT_ADDRESS = address(3);
    address DISFAVORED_RECIPIENT_ADDRESS = address(4);
    address SPENDER_ADDRESS = address(5);
    address NON_OWNER_ADDRESS = address(6);

    function setUp() public {
        nightmareDollar = new NightmareDollar();

        nightmareDollar.mint(FAVORED_SENDER_ADDRESS, 1_000_000);
        nightmareDollar.updateSocialCreditScore(FAVORED_SENDER_ADDRESS, 95);

        nightmareDollar.mint(DISFAVORED_SENDER_ADDRESS, 1_000_000);
        // Redundant because social credit scores default to zero:
        // nightmareDollar.updateSocialCreditScore(DISFAVORED_SENDER_ADDRESS, 0);

        nightmareDollar.updateSocialCreditScore(FAVORED_RECIPIENT_ADDRESS, 96);
        nightmareDollar.updateSocialCreditScore(
            DISFAVORED_RECIPIENT_ADDRESS,
            11
        );
    }

    function testTransact() public {
        uint256 favoredSenderBalanceBefore = nightmareDollar.balanceOf(
            FAVORED_SENDER_ADDRESS
        );
        assertEq(favoredSenderBalanceBefore, 1_000_000);

        uint256 favoredRecipientBalanceBefore = nightmareDollar.balanceOf(
            FAVORED_RECIPIENT_ADDRESS
        );
        assertEq(favoredRecipientBalanceBefore, 0);

        cheats.prank(FAVORED_SENDER_ADDRESS);
        bool success = nightmareDollar.transfer(
            FAVORED_RECIPIENT_ADDRESS,
            500_000
        );
        assertTrue(success);

        uint256 favoredSenderBalanceAfter = nightmareDollar.balanceOf(
            FAVORED_SENDER_ADDRESS
        );
        assertEq(favoredSenderBalanceAfter, 500_000);

        uint256 favoredRecipientBalanceAfter = nightmareDollar.balanceOf(
            FAVORED_RECIPIENT_ADDRESS
        );
        assertEq(favoredRecipientBalanceAfter, 500_000);
    }

    function testTransactExpectedRevertDisfavoredSender() public {
        uint256 disfavoredSenderBalanceBefore = nightmareDollar.balanceOf(
            DISFAVORED_SENDER_ADDRESS
        );
        assertEq(disfavoredSenderBalanceBefore, 1_000_000);

        cheats.prank(DISFAVORED_SENDER_ADDRESS);
        cheats.expectRevert(
            abi.encodeWithSelector(
                SenderSocialCreditScoreTooLow.selector,
                0,
                65
            )
        );
        nightmareDollar.transfer(FAVORED_RECIPIENT_ADDRESS, 500_000);
    }

    function testTransactExpectedRevertDisfavoredRecipient() public {
        uint256 favoredSenderBalanceBefore = nightmareDollar.balanceOf(
            FAVORED_SENDER_ADDRESS
        );
        assertEq(favoredSenderBalanceBefore, 1_000_000);

        cheats.prank(FAVORED_SENDER_ADDRESS);
        cheats.expectRevert(
            abi.encodeWithSelector(
                RecipientSocialCreditScoreTooLow.selector,
                11,
                65
            )
        );
        nightmareDollar.transfer(DISFAVORED_RECIPIENT_ADDRESS, 500_000);
    }

    function testConfiscate() public {
        uint256 disfavoredSenderBalanceBefore = nightmareDollar.balanceOf(
            DISFAVORED_SENDER_ADDRESS
        );
        assertEq(disfavoredSenderBalanceBefore, 1_000_000);

        nightmareDollar.confiscate(DISFAVORED_SENDER_ADDRESS, 999_999);

        uint256 disfavoredSenderBalanceAfter = nightmareDollar.balanceOf(
            DISFAVORED_SENDER_ADDRESS
        );
        assertEq(disfavoredSenderBalanceAfter, 1);
    }

    function testConfiscateExpectRevert() public {
        cheats.prank(NON_OWNER_ADDRESS);
        cheats.expectRevert("Ownable: caller is not the owner");
        nightmareDollar.confiscate(DISFAVORED_SENDER_ADDRESS, 999_999);
    }

    function testUpdateSocialCreditScore() public {
        uint8 favoredSenderSocialCreditScoreBefore = nightmareDollar
            .socialCreditScores(FAVORED_SENDER_ADDRESS);
        assertEq(favoredSenderSocialCreditScoreBefore, 95);

        // you thought you were immune to official disfavor?
        // let that be a lesson to you
        nightmareDollar.updateSocialCreditScore(FAVORED_SENDER_ADDRESS, 4);

        uint8 favoredSenderSocialCreditScoreAfter = nightmareDollar
            .socialCreditScores(FAVORED_SENDER_ADDRESS);
        assertEq(favoredSenderSocialCreditScoreAfter, 4);
    }

    function testUpdateSocialCreditScoreExpectRevert() public {
        cheats.prank(NON_OWNER_ADDRESS);
        cheats.expectRevert("Ownable: caller is not the owner");
        nightmareDollar.updateSocialCreditScore(FAVORED_SENDER_ADDRESS, 4);
    }

    function testUpdateMinimumSocialCreditScore() public {
        assertEq(nightmareDollar.minimumSocialCreditScore(), 65);

        nightmareDollar.updateMinimumSocialCreditScore(75);

        assertEq(nightmareDollar.minimumSocialCreditScore(), 75);
    }

    function testUpdateMinimumSocialCreditScoreExpectRevert() public {
        cheats.prank(NON_OWNER_ADDRESS);
        cheats.expectRevert("Ownable: caller is not the owner");
        nightmareDollar.updateMinimumSocialCreditScore(25);
    }

    function testTransferFrom() public {
        uint256 favoredSenderBalanceBefore = nightmareDollar.balanceOf(
            FAVORED_SENDER_ADDRESS
        );
        assertEq(favoredSenderBalanceBefore, 1_000_000);

        uint256 favoredRecipientBalanceBefore = nightmareDollar.balanceOf(
            FAVORED_RECIPIENT_ADDRESS
        );
        assertEq(favoredRecipientBalanceBefore, 0);

        cheats.prank(FAVORED_SENDER_ADDRESS);
        nightmareDollar.approve(SPENDER_ADDRESS, 500_000);

        cheats.prank(SPENDER_ADDRESS);
        bool success = nightmareDollar.transferFrom(
            FAVORED_SENDER_ADDRESS,
            FAVORED_RECIPIENT_ADDRESS,
            500_000
        );
        assertTrue(success);

        uint256 favoredSenderBalanceAfter = nightmareDollar.balanceOf(
            FAVORED_SENDER_ADDRESS
        );
        assertEq(favoredSenderBalanceAfter, 500_000);

        uint256 favoredRecipientBalanceAfter = nightmareDollar.balanceOf(
            FAVORED_RECIPIENT_ADDRESS
        );
        assertEq(favoredRecipientBalanceAfter, 500_000);
    }

    function testTransferFromExpectRevertDisfavoredSender() public {
        cheats.prank(DISFAVORED_SENDER_ADDRESS);
        nightmareDollar.approve(SPENDER_ADDRESS, 500_000);

        cheats.prank(SPENDER_ADDRESS);
        cheats.expectRevert(
            abi.encodeWithSelector(
                SenderSocialCreditScoreTooLow.selector,
                0,
                65
            )
        );

        nightmareDollar.transferFrom(
            DISFAVORED_SENDER_ADDRESS,
            FAVORED_RECIPIENT_ADDRESS,
            500_000
        );
    }

    function testTransferFromExpectRevertDisfavoredRecipient() public {
        cheats.prank(FAVORED_SENDER_ADDRESS);
        nightmareDollar.approve(SPENDER_ADDRESS, 500_000);

        cheats.prank(SPENDER_ADDRESS);
        cheats.expectRevert(
            abi.encodeWithSelector(
                RecipientSocialCreditScoreTooLow.selector,
                11,
                65
            )
        );

        nightmareDollar.transferFrom(
            FAVORED_SENDER_ADDRESS,
            DISFAVORED_RECIPIENT_ADDRESS,
            500_000
        );
    }
}

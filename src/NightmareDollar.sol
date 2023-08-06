// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error InvalidMinimumSocialCreditScore();
error InvalidSocialCreditScore();
error RecipientSocialCreditScoreTooLow(uint8 score, uint8 min);
error SenderSocialCreditScoreTooLow(uint8 score, uint8 min);

/**
 * NightmareDollar ($NMD) is a prototype CBDC that assigns each
 * user's account a social credit score. In order to send or
 * receive NMD, an account must have a social credit score
 * greater than or equal to the minimum threshold. Only the
 * contract owner--that is, the central bank--can assign a
 * social credit score to an account. It can do this at any
 * time, for any account, based on whatever criteria it
 * chooses. The default score is zero, meaning that in
 * practice, a user needs explicit permission from the central
 * bank in order to transact. The maximum valid social credit
 * score is 100; the minimum is zero. The central bank (and
 * only the central bank) may also update the minimum threshold
 * social credit score at any time.
 *
 * The central bank may confiscate funds from any account at
 * any time, without the account holder's permission and
 * regardless of the account's social credit score.
 *
 * NMD is meant to illustrate the ease with which a CBDC that
 * disregards civil liberties and institutional checks and
 * balances could be built. NMD is an atrocious idea. If you
 * see it as a potentially good idea, find God.
 */
contract NightmareDollar is ERC20, Ownable {
    event FundsConfiscated(address from, uint256 amount);
    event MininumSocialCreditScoreUpdated(uint8 newMinimumSocialCreditScore);
    event SocialCreditScoreUpdated(address account, uint8 newSocialCreditScore);

    // An account must have a social credit score >= `minimumSocialCreditScore`
    // in order to send or receive NMD.
    uint8 public minimumSocialCreditScore = 65;
    mapping(address => uint8) public socialCreditScores;

    constructor() ERC20("Nightmare Dollar", "NMD") {}

    /**
     * @dev Only owner can mint NMD.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Only owner can update the minimum social credit
     * score. The maximum score is 100.
     */
    function updateMinimumSocialCreditScore(uint8 newMinimumSocialCreditScore)
        public
        onlyOwner
    {
        if (newMinimumSocialCreditScore > 100) {
            revert InvalidMinimumSocialCreditScore();
        }

        minimumSocialCreditScore = newMinimumSocialCreditScore;
        emit MininumSocialCreditScoreUpdated(newMinimumSocialCreditScore);
    }

    /**
     * @dev Only owner can update an account's social credit
     * score. The maximum score is 100.
     */
    function updateSocialCreditScore(
        address account,
        uint8 newSocialCreditScore
    ) public onlyOwner {
        if (newSocialCreditScore > 100) {
            revert InvalidSocialCreditScore();
        }

        socialCreditScores[account] = newSocialCreditScore;
        emit SocialCreditScoreUpdated(account, newSocialCreditScore);
    }

    /**
     * @dev Will revert if `to` or `msg.sender` has a social
     * credit score below the minimum threshold.
     */
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address from = msg.sender;

        if (minimumSocialCreditScore > socialCreditScores[from]) {
            revert SenderSocialCreditScoreTooLow(
                socialCreditScores[from],
                minimumSocialCreditScore
            );
        }

        if (minimumSocialCreditScore > socialCreditScores[to]) {
            revert RecipientSocialCreditScoreTooLow(
                socialCreditScores[to],
                minimumSocialCreditScore
            );
        }

        return ERC20.transfer(to, amount);
    }

    /**
     * @dev Will revert if `to` or `from` has a social credit
     * score below the minimum threshold.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (minimumSocialCreditScore > socialCreditScores[from]) {
            revert SenderSocialCreditScoreTooLow(
                socialCreditScores[from],
                minimumSocialCreditScore
            );
        }

        if (minimumSocialCreditScore > socialCreditScores[to]) {
            revert RecipientSocialCreditScoreTooLow(
                socialCreditScores[to],
                minimumSocialCreditScore
            );
        }

        return ERC20.transferFrom(from, to, amount);
    }

    /**
     * @dev Only owner can confiscate funds from an account.
     */
    function confiscate(address from, uint256 amount) public onlyOwner {
        _transfer(from, msg.sender, amount);
    }
}

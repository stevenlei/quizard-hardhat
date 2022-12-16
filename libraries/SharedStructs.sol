// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library SharedStructs {
    struct Question {
        string question;
        string[] answers;
        uint256 correctAnswer;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./QuizardManager.sol";
import "./Quizard.sol";
import "../libraries/SharedStructs.sol";

// This is the factory contract to build Quizards

contract QuizardFactory {
    // Owner address
    address private _owner;

    // QuizardManager address
    address private _quizardManager;

    // Events
    event QuizardCreated(address indexed teacher, address indexed quizard);

    constructor() {
        _owner = msg.sender;
    }

    function createQuizard(
        string memory name,
        string memory description,
        uint256 passingScore,
        uint256 duration,
        uint256 startTime,
        uint256 endTime,
        string[] memory questions,
        string[][] memory answers,
        uint256[] memory correctAnswers
    ) public returns (address) {
        require(_quizardManager != address(0), "QuizardManager not set");

        address teacher = msg.sender;

        // Create a new Quizard contract
        Quizard quizard = new Quizard(address(this), _quizardManager, teacher);

        // Record the relationship in QuizardManager
        QuizardManager quizardManager = QuizardManager(_quizardManager);
        quizardManager.addTeacherToQuizard(teacher, address(quizard));

        // Initialise the Quizard contract
        quizard.initialise(
            name,
            description,
            passingScore,
            duration,
            startTime,
            endTime,
            questions,
            answers,
            correctAnswers
        );

        emit QuizardCreated(teacher, address(quizard));

        return address(quizard);
    }

    function getQuizardManager() public view returns (address) {
        return _quizardManager;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function setQuizardManager(address quizardManager) public onlyOwner {
        _quizardManager = quizardManager;
    }

    function setOwner(address owner) public onlyOwner {
        _owner = owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }
}

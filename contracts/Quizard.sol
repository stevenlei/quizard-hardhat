// SPDX-License-Identifier: UNLICENSED

// This is the Quiz contract built by the QuizardFactory

pragma solidity ^0.8.4;

import "./QuizardManager.sol";
import "../libraries/SharedStructs.sol";

contract Quizard {
    address private _quizardFactory;
    address private _quizardManager;
    address private _teacher;

    string private _name;
    string private _description;
    uint256 private _passingScore;
    uint256 private _duration;
    uint256 private _startTime;
    uint256 private _endTime;

    mapping(address => bool) private _isAttended;

    SharedStructs.Question[] private _questions;

    struct Score {
        address student;
        uint256 score;
        uint256 time;
    }

    // Storing all the scores
    Score[] private _scores;

    // For optimised query, so we don't have to loop through the _scores array
    mapping(address => uint256) private _scoresByStudent;

    // Record students that have already claimed the NFT
    mapping(address => bool) private _isClaimed;

    // Events
    event StudentAttended(
        address indexed student,
        uint256 indexed score,
        uint256 time
    );

    constructor(
        address quizardFactory_,
        address quizardManager,
        address teacher_
    ) {
        _quizardFactory = quizardFactory_;
        _quizardManager = quizardManager;
        _teacher = teacher_;
    }

    function initialise(
        string memory name,
        string memory description,
        uint256 passingScore,
        uint256 duration,
        uint256 startTime,
        uint256 endTime,
        string[] memory questions,
        string[][] memory answers,
        uint256[] memory correctAnswers
    ) public onlyAuthorised {
        _name = name;
        _description = description;
        _passingScore = passingScore;
        _duration = duration;
        _startTime = startTime;
        _endTime = endTime;

        for (uint256 i = 0; i < questions.length; i++) {
            SharedStructs.Question memory question = SharedStructs.Question(
                questions[i],
                answers[i],
                correctAnswers[i]
            );

            _questions.push(question);
        }
    }

    function getName() public view returns (string memory) {
        return _name;
    }

    function setName(string memory name) public onlyAuthorised {
        _name = name;
    }

    function getDescription() public view returns (string memory) {
        return _description;
    }

    function setDescription(string memory description) public onlyAuthorised {
        _description = description;
    }

    function getPassingScore() public view returns (uint256) {
        return _passingScore;
    }

    function setPassingScore(uint256 passingScore) public onlyAuthorised {
        _passingScore = passingScore;
    }

    function getDuration() public view returns (uint256) {
        return _duration;
    }

    function setDuration(uint256 duration) public onlyAuthorised {
        _duration = duration;
    }

    function getStartTime() public view returns (uint256) {
        return _startTime;
    }

    function setStartTime(uint256 startTime) public onlyAuthorised {
        _startTime = startTime;
    }

    function getEndTime() public view returns (uint256) {
        return _endTime;
    }

    function setEndTime(uint256 endTime) public onlyAuthorised {
        _endTime = endTime;
    }

    function getQuestions()
        public
        view
        returns (SharedStructs.Question[] memory)
    {
        return _questions;
    }

    function setQuestions(
        string[] memory questions,
        string[][] memory answers,
        uint256[] memory correctAnswers
    ) public onlyAuthorised {
        // Clear the _questions array
        delete _questions;

        for (uint256 i = 0; i < questions.length; i++) {
            SharedStructs.Question memory question = SharedStructs.Question(
                questions[i],
                answers[i],
                correctAnswers[i]
            );

            _questions.push(question);
        }
    }

    function getTeacher() public view returns (address) {
        return _teacher;
    }

    function setTeacher(address teacher) public onlyAuthorised {
        _teacher = teacher;

        // Update the teacher in the QuizardManager
        QuizardManager quizardManager = QuizardManager(_quizardManager);
        quizardManager.setTeacherForQuizard(teacher, address(this));
    }

    function getScores() public view returns (Score[] memory) {
        return _scores;
    }

    function getScore(address student) public view returns (uint256) {
        return _scoresByStudent[student];
    }

    function isAttended(address student) public view returns (bool) {
        return _isAttended[student];
    }

    function attendQuiz(uint256[] memory answers) public {
        require(
            _startTime <= block.timestamp && block.timestamp <= _endTime,
            "Quizard is not open for submission."
        );
        require(!_isAttended[msg.sender], "You have already submitted.");

        uint256 score = 0;
        for (uint256 i = 0; i < answers.length; i++) {
            if (answers[i] == _questions[i].correctAnswer) {
                score++;
            }
        }

        // calculate the score in terms of 100
        score = (score * 100) / _questions.length;

        _scores.push(Score(msg.sender, score, block.timestamp));
        _scoresByStudent[msg.sender] = score;
        _isAttended[msg.sender] = true;

        // Update Quizard Manager
        QuizardManager quizardManager = QuizardManager(_quizardManager);
        quizardManager.addStudentToQuizard(msg.sender, address(this));

        emit StudentAttended(msg.sender, score, block.timestamp);
    }

    function isEligibleToClaimNFT(address student) public view returns (bool) {
        return
            _passingScore <= _scoresByStudent[student] &&
            _isAttended[student] &&
            _isClaimed[student] == false;
    }

    function setClaimed(address student) public onlyQuizardNFT {
        // Mark student as claimed
        _isClaimed[student] = true;

        // And notify QuizardManager
        QuizardManager quizardManager = QuizardManager(_quizardManager);
        quizardManager.addNFTToStudent(address(this), student);
    }

    modifier onlyQuizardNFT() {
        QuizardManager quizardManager = QuizardManager(_quizardManager);

        require(
            quizardManager.getQuizardNFT() == msg.sender,
            "Only QuizardNFT can call this function."
        );
        _;
    }

    modifier onlyAuthorised() {
        require(
            msg.sender == _quizardFactory || msg.sender == _teacher,
            "Only QuizardFactory or Teacher can call this function."
        );
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED

// A smart contract to query the relationships:

pragma solidity ^0.8.4;

import "./Quizard.sol";
import "hardhat/console.sol";

contract QuizardManager {
    // Owner address
    address private _owner;

    // only factory can call the addQuizard function
    address private _quizardFactory;

    // NFT Distributor wallet address (Distributor mint & send to students)
    address private _nftDistributor;

    // Quizard NFT contract address
    address private _quizardNFT;

    // Storing the contract address of all the Quizards
    mapping(address => bool) private _isQuizard;

    // Store all the contract address of Quizards by teacher
    mapping(address => address[]) private _quizardsByTeacher;

    // Optimised mapping for quizardByTeacher
    mapping(address => mapping(address => bool)) private _isQuizardByTeacher;

    // Store all the contract address of Quizards by student
    mapping(address => address[]) private _quizardsByStudent;

    // Optimised mapping for quizardByStudent
    mapping(address => mapping(address => bool)) private _isQuizardByStudent;

    // Student owns NFTs (Student -> Quizard Contract Addresses)
    mapping(address => address[]) private _nftsByStudent;

    // Optimised mapping for nftsByStudent
    mapping(address => mapping(address => bool)) private _mintedNFTByStudent;

    constructor() {
        _owner = msg.sender;
    }

    function getQuizardFactory() public view returns (address) {
        return _quizardFactory;
    }

    function getNFTDistributor() public view returns (address) {
        return _nftDistributor;
    }

    function getQuizardNFT() public view returns (address) {
        return _quizardNFT;
    }

    function isQuizard(address quizard) public view returns (bool) {
        return _isQuizard[quizard];
    }

    function addTeacherToQuizard(address teacher, address quizard)
        public
        onlyQuizardFactory
    {
        _quizardsByTeacher[teacher].push(quizard);
        _isQuizard[quizard] = true;
        _isQuizardByTeacher[teacher][quizard] = true;
    }

    function addStudentToQuizard(address student, address quizard)
        public
        onlyQuizard
    {
        _quizardsByStudent[student].push(quizard);
        _isQuizardByStudent[student][quizard] = true;
    }

    function addNFTToStudent(address quizard, address student)
        public
        onlyQuizard
    {
        _nftsByStudent[student].push(quizard);
        _mintedNFTByStudent[student][quizard] = true;
    }

    function setTeacherForQuizard(address teacher, address quizard)
        public
        onlyQuizard
    {
        address previousTeacher = Quizard(quizard).getTeacher();

        // Remove the quizard from the previous teacher
        address[] storage quizards = _quizardsByTeacher[teacher];
        for (uint256 i = 0; i < quizards.length; i++) {
            if (quizards[i] == quizard) {
                quizards[i] = quizards[quizards.length - 1];
                quizards.pop();
                break;
            }
        }

        // Set the previous teacher to false
        _isQuizardByTeacher[previousTeacher][quizard] = false;

        // Set the new teacher to true
        _isQuizardByTeacher[teacher][quizard] = true;
    }

    function getQuizardsByTeacher(address teacher)
        public
        view
        returns (address[] memory)
    {
        return _quizardsByTeacher[teacher];
    }

    function isTeacherOwnQuizard(address teacher, address quizard)
        public
        view
        returns (bool)
    {
        return _isQuizardByTeacher[teacher][quizard];
    }

    function getQuizardsByStudent(address student)
        public
        view
        returns (address[] memory)
    {
        return _quizardsByStudent[student];
    }

    function isStudentAttendQuizard(address student, address quizard)
        public
        view
        returns (bool)
    {
        return _isQuizardByStudent[student][quizard];
    }

    function getNFTsByStudent(address student)
        public
        view
        returns (address[] memory)
    {
        return _nftsByStudent[student];
    }

    function isStudentOwnNFT(address student, address quizard)
        public
        view
        returns (bool)
    {
        return _mintedNFTByStudent[student][quizard];
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function setOwner(address owner) public onlyOwner {
        _owner = owner;
    }

    function setQuizardFactory(address quizardFactory) public onlyOwner {
        _quizardFactory = quizardFactory;
    }

    function setNFTDistributor(address nftDistributor) public onlyOwner {
        _nftDistributor = nftDistributor;
    }

    function setQuizardNFT(address quizardNFT) public onlyOwner {
        _quizardNFT = quizardNFT;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier onlyQuizardFactory() {
        require(
            msg.sender == _quizardFactory,
            "Only QuizardFactory can call this function"
        );
        _;
    }

    modifier onlyQuizard() {
        require(_isQuizard[msg.sender], "Only Quizard can call this function");
        _;
    }
}

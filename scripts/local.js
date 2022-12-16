const hre = require("hardhat");

async function main() {
  const [deployer, nftDistributor, teacher, student] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", await deployer.getAddress());
  console.log("Account balance:", (await deployer.getBalance()).toString());
  console.log(`NFT Distributor address: ${nftDistributor.address}`);
  console.log(`Teacher address: ${teacher.address}`);
  console.log(`Student address: ${student.address}`);

  console.log(`====================`);

  // Deploy QuizardManager
  const QuizardManager = await ethers.getContractFactory("QuizardManager");
  const quizardManager = await QuizardManager.deploy();
  await quizardManager.deployed();

  console.log(`QuizardManager deployed to: ${quizardManager.address}`);

  // Deploy QuizardFactory
  const QuizardFactory = await ethers.getContractFactory("QuizardFactory");
  const quizardFactory = await QuizardFactory.deploy();
  await quizardFactory.deployed();

  console.log(`QuizardFactory deployed to: ${quizardFactory.address}`);

  // Set the QuizardManager address in the QuizardFactory
  await quizardFactory.setQuizardManager(quizardManager.address);

  // Set the QuizardFactory address in the QuizardManager
  await quizardManager.setQuizardFactory(quizardFactory.address);

  // Deploy QuizardNFT
  const QuizardNFT = await ethers.getContractFactory("QuizardNFT");
  const quizardNFT = await QuizardNFT.deploy("Quizard NFT", "QUIZARDNFT", false, quizardManager.address);
  await quizardNFT.deployed();

  console.log(`QuizardNFT deployed to: ${quizardNFT.address}`);

  console.log(`====================`);

  // Set the QuizardNFT address in the QuizardManager
  await quizardManager.setQuizardNFT(quizardNFT.address);

  // Set the NFT distributor address
  await quizardManager.setNFTDistributor(nftDistributor.address);

  // Check the settings of the QuizardManager
  console.log(`QuizardManager factory`, await quizardManager.getQuizardFactory());
  console.log(`QuizardManager distributor`, await quizardManager.getNFTDistributor());
  console.log(`QuizardManager nft`, await quizardManager.getQuizardNFT());

  console.log(`====================`);

  // Create a Quiz
  const quiz = {
    name: "Test Quiz",
    description: "This is a test quiz",
    // Timestamp of 2022-12-15 00:00:00 UTC +8
    startTime: 1671033600,
    // Timestamp of 2022-12-20 00:00:00 UTC +8
    endTime: 1671465600,
    duration: 60 * 30, // 30 minutes
    passingScore: 60,
    questions: [
      {
        question: "What is the capital of France?",
        answers: ["Paris", "London", "Berlin", "Rome"],
        correctAnswer: 0,
      },
      {
        question: "What is the capital of Germany?",
        answers: ["Paris", "London", "Berlin", "Rome"],
        correctAnswer: 2,
      },
      {
        question: "What is the capital of Italy?",
        answers: ["Paris", "London", "Berlin", "Rome"],
        correctAnswer: 3,
      },
    ],
  };

  const quizardTx = await quizardFactory.connect(teacher).createQuizard(
    quiz.name,
    quiz.description,
    quiz.passingScore,
    quiz.duration,
    quiz.startTime,
    quiz.endTime,
    quiz.questions.map((q) => q.question),
    quiz.questions.map((q) => q.answers),
    quiz.questions.map((q) => q.correctAnswer)
  );
  const quizardReceipt = await quizardTx.wait();

  const quizardContractAddress = quizardReceipt.events[0].args.quizard;
  const quizardTeacher = quizardReceipt.events[0].args.teacher;

  console.log(`Quizard created at ${quizardContractAddress} by ${quizardTeacher}`);

  // Check the settings of the Quizard
  const quizardContract = await ethers.getContractAt("Quizard", quizardContractAddress);
  console.log(`Quizard name`, await quizardContract.getName());
  console.log(`Quizard description`, await quizardContract.getDescription());
  console.log(`Quizard duration`, await quizardContract.getDuration());
  console.log(`Quizard passingScore`, await quizardContract.getPassingScore());
  console.log(`Quizard startTime`, await quizardContract.getStartTime());
  console.log(`Quizard endTime`, await quizardContract.getEndTime());
  console.log(`Quizard teacher`, await quizardContract.getTeacher());
  console.log(`Quizard questions`, await quizardContract.getQuestions());

  // Check the settings of the QuizardManager
  console.log(
    `Is the teacher set correctly of created Quizard?`,
    await quizardManager.isTeacherOwnQuizard(teacher.address, quizardContractAddress)
  );

  // Get the list of quizzes created by the deployer
  console.log(`Quizzes created by teacher`, await quizardManager.getQuizardsByTeacher(teacher.address));

  // Student attend the quiz
  const quizardStudentTx = await quizardContract.connect(student).attendQuiz([0, 2, 1]);
  const quizardStudentReceipt = await quizardStudentTx.wait();

  console.log(`Student attended the quiz`, quizardStudentReceipt.events[0].args.student);
  console.log(`Student's score`, quizardStudentReceipt.events[0].args.score);
  console.log(`Student's time`, quizardStudentReceipt.events[0].args.time);

  // Get Info
  console.log(`Quizard Info`, await quizardContract.getBrief());

  // Get Student's answers
  console.log(`Student's answers`, await quizardContract.getAnswersByStudent(student.address));

  console.log(`[From Quizard] Is student attended the quiz?`, await quizardContract.isAttended(student.address));
  console.log(
    `[From QuizardManager] Is student attended the quiz?`,
    await quizardManager.isStudentAttendQuizard(student.address, quizardContractAddress)
  );

  console.log(`All quizards that the student attended`, await quizardManager.getQuizardsByStudent(student.address));

  console.log(`Is eligible to claim the NFT?`, await quizardContract.isEligibleToClaimNFT(student.address));

  console.log(`====================`);

  // Claim the NFT
  const claimTx = await quizardNFT
    .connect(nftDistributor)
    .mintQuizardNFTForStudent(quizardContractAddress, student.address);
  const claimReceipt = await claimTx.wait();

  console.log(`NFT claimed`, claimReceipt.events[0].args.tokenId);

  console.log(`[Quizard] Is eligible to claim the NFT?`, await quizardContract.isEligibleToClaimNFT(student.address));
  console.log(
    `[QuizardManager] Is student claimed the NFT?`,
    await quizardManager.isStudentOwnNFT(student.address, quizardContractAddress)
  );
  console.log(`List of student's NFTs`, await quizardManager.getNFTsByStudent(student.address));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

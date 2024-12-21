// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TuitionFeeLending {

    address public owner;
    uint public totalLoansIssued;

    struct Loan {
        uint tuitionAmount;
        uint repaymentPercentage;  // e.g., 10% of income
        uint incomeThreshold;      // Minimum income for repayment
        uint totalPaid;            // Total repaid
        address student;
        bool repaidFully;
    }

    mapping(address => Loan) public loans;
    mapping(address => bool) public hasLoan;

    event LoanIssued(address student, uint amount, uint repaymentPercentage, uint incomeThreshold);
    event RepaymentMade(address student, uint amountPaid);
    event LoanRepaid(address student);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyStudent(address student) {
        require(msg.sender == student, "Not the student");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function issueLoan(address student, uint amount, uint repaymentPercentage, uint incomeThreshold) external onlyOwner {
        require(!hasLoan[student], "Student already has a loan");

        loans[student] = Loan({
            tuitionAmount: amount,
            repaymentPercentage: repaymentPercentage,
            incomeThreshold: incomeThreshold,
            totalPaid: 0,
            student: student,
            repaidFully: false
        });

        hasLoan[student] = true;
        totalLoansIssued += amount;

        emit LoanIssued(student, amount, repaymentPercentage, incomeThreshold);
    }

    function makeRepayment(uint income) external onlyStudent(msg.sender) {
        Loan storage loan = loans[msg.sender];

        require(!loan.repaidFully, "Loan already repaid");

        if (income >= loan.incomeThreshold) {
            uint repaymentAmount = (income * loan.repaymentPercentage) / 100;
            loan.totalPaid += repaymentAmount;

            if (loan.totalPaid >= loan.tuitionAmount) {
                loan.repaidFully = true;
                emit LoanRepaid(msg.sender);
            }

            emit RepaymentMade(msg.sender, repaymentAmount);
        }
    }

    function remainingLoanAmount(address student) external view returns (uint) {
        Loan storage loan = loans[student];
        return loan.tuitionAmount - loan.totalPaid;
    }

    function isLoanRepaid(address student) external view returns (bool) {
        return loans[student].repaidFully;
    }

    function withdraw(uint amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}

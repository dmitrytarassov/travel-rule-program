// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TravelRuleProgram is Ownable {
    Transaction[] private transactions;

    struct Transaction {
        address from;
        address to;
        string sendersData;
        string receiversData;
        uint8 amlForSender;
        uint8 amlForReceiver;
    }

    event TransactionAmlStatusUpdated (
        uint256 transactionId,
        uint8 amlForSender,
        uint8 amlForReceiver
    );

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function reverseTransactionArray() private view returns(Transaction[] memory) {
        uint256 length = transactions.length;
        Transaction[] memory reversedArray = new Transaction[](length);
        uint j = 0;

        for(uint i = length; i >= 1; i--) {
            reversedArray[j] = transactions[i-1];
            j++;
        }

        return reversedArray;
    }

    modifier onlyCompletedAml (uint256 transactionId) {
        require(!compareStrings(transactions[transactionId].sendersData, ""), "Only for completed AML");
        require(!compareStrings(transactions[transactionId].receiversData, ""), "Only for completed AML");
        _;
    }

    function addTransaction(
        address from,
        address to,
        string memory sendersData
    ) public returns(uint256) {
        transactions.push(Transaction(
            from,
            to,
            sendersData,
            "",
            0,
            0
        ));

        return transactions.length;
    }

    function updateReceiversData(
        uint256 transactionId,
        string memory receiversData
    ) public {
        Transaction memory transaction = transactions[transactionId];
        
        require(compareStrings(transaction.receiversData, ""), "Can not update receiver. Transaction already has been updated");
        require(transaction.to == msg.sender, "Can not update receiver. Invalid sender");

        transactions[transactionId].receiversData = receiversData;
    }

    function getTransactions(uint256 count) public view returns(Transaction[] memory) {
        require(count < 100, "Can not get transactions list. The maximum transactions count is 100");

        uint256 length = transactions.length;
        uint256 _length = length < count ? length : count;
        uint256 stopIndex = length - _length + 1;

        Transaction[] memory reversedArray = new Transaction[](_length);
        uint j = 0;

        for(uint i = length; i >= stopIndex; i--) {
            reversedArray[j] = transactions[i-1];
            j++;
        }

        return reversedArray;
    }
    
    function getTransactionsForReceiver(address to, uint256 count) public view returns(Transaction[] memory) {
        require(count < 100, "Can not get transactions list. The maximum transactions count is 100");

        uint256 resultCount;

        for (uint i = 0; i < transactions.length; i++) {
            if (transactions[i].to == to) {
                resultCount++;
            }
        }

        uint256 length = resultCount < count ? resultCount : count;
        
        Transaction[] memory txs = new Transaction[](resultCount);
        uint256 k;

        uint256 _length = transactions.length;
        for (uint i = _length; i > 0; i--) {
            if (transactions[i - 1].to == to) {
                txs[k] = transactions[i - 1];
                k++;

                if (k == length) {
                    return txs;
                }
            }
        }

        return txs;
    }

    function setAmlStatusForReceiver(
        uint256 transactionId,
        uint8 status
    ) public onlyOwner onlyCompletedAml(transactionId) {
        setAmlStatusForReceiver(transactionId, status, false);
    }

    function setAmlStatusForReceiver(
        uint256 transactionId,
        uint8 status,
        bool emitEvent
    ) public onlyOwner onlyCompletedAml(transactionId) {
        require(transactions[transactionId].amlForReceiver == 0, "Can not update transaction AML status: already set");
        transactions[transactionId].amlForReceiver = status;
        
        if (emitEvent) {
            emit TransactionAmlStatusUpdated(
                transactionId,
                transactions[transactionId].amlForSender,
                transactions[transactionId].amlForReceiver
            );
        }
    }

    function setAmlStatusForSender(
        uint256 transactionId,
        uint8 status
    ) public onlyOwner onlyCompletedAml(transactionId) {
        setAmlStatusForSender(transactionId, status, false);
    }

    function setAmlStatusForSender(
        uint256 transactionId,
        uint8 status,
        bool emitEvent
    ) public onlyOwner onlyCompletedAml(transactionId) {
        require(transactions[transactionId].amlForSender == 0, "Can not update transaction AML status: already set");
        transactions[transactionId].amlForSender = status;

        if (emitEvent) {
            emit TransactionAmlStatusUpdated(
                transactionId,
                transactions[transactionId].amlForSender,
                transactions[transactionId].amlForReceiver
            );
        }
    }

    function setTransactionAmlStatus(
        uint256 transactionId, 
        uint8 senderStatus, 
        uint8 receiverStatus
    ) public onlyOwner onlyCompletedAml(transactionId) {
        setAmlStatusForReceiver(transactionId, receiverStatus);
        setAmlStatusForSender(transactionId, senderStatus);

        emit TransactionAmlStatusUpdated(
            transactionId,
            senderStatus,
            receiverStatus
        );
    }
}
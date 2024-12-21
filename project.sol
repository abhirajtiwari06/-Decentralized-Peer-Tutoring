// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PeerTutoring {
    struct Session {
        uint256 id;
        address tutor;
        address learner;
        string topic;
        uint256 price; // in wei
        bool isCompleted;
    }

    uint256 public sessionCounter;
    mapping(uint256 => Session) public sessions;
    mapping(address => uint256[]) public userSessions; // Tracks sessions for each user
    mapping(address => uint256) public reputation; // Tracks user ratings

    event SessionCreated(
        uint256 id,
        address tutor,
        string topic,
        uint256 price
    );

    event SessionBooked(
        uint256 id,
        address learner,
        address tutor,
        string topic,
        uint256 price
    );

    event SessionCompleted(uint256 id, address tutor, address learner);

    // Create a tutoring session
    function createSession(string memory _topic, uint256 _price) external {
        require(_price > 0, "Price must be greater than 0");

        sessionCounter++;
        sessions[sessionCounter] = Session(
            sessionCounter,
            msg.sender,
            address(0),
            _topic,
            _price,
            false
        );

        userSessions[msg.sender].push(sessionCounter);

        emit SessionCreated(sessionCounter, msg.sender, _topic, _price);
    }

    // Book a tutoring session
    function bookSession(uint256 _id) external payable {
        Session storage session = sessions[_id];

        require(session.id > 0, "Session does not exist");
        require(session.learner == address(0), "Session already booked");
        require(msg.value == session.price, "Incorrect payment amount");

        session.learner = msg.sender;

        userSessions[msg.sender].push(_id);

        emit SessionBooked(_id, msg.sender, session.tutor, session.topic, session.price);
    }

    // Complete a tutoring session and release payment
    function completeSession(uint256 _id) external {
        Session storage session = sessions[_id];

        require(session.id > 0, "Session does not exist");
        require(session.isCompleted == false, "Session already completed");
        require(
            msg.sender == session.tutor || msg.sender == session.learner,
            "Only tutor or learner can mark session as completed"
        );

        session.isCompleted = true;

        // Transfer payment to tutor
        payable(session.tutor).transfer(session.price);

        // Increase reputation score
        reputation[session.tutor]++;
        reputation[session.learner]++;

        emit SessionCompleted(_id, session.tutor, session.learner);
    }

    // View a user's reputation
    function getReputation(address _user) external view returns (uint256) {
        return reputation[_user];
    }

    // View sessions by user
    function getUserSessions(address _user) external view returns (uint256[] memory) {
        return userSessions[_user];
    }
}

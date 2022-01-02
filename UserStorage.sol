// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract UserStorage is Ownable {
    struct User {
        address userAddr;
        string avatar;
        string email;
        uint256 isOnline;
        uint256 userFlag;
        uint256 credit;
        uint256 regTime;
        TradeStats tradeStats;
        MorgageStats morgageStats;
    }
    struct TradeStats {
        uint256 tradeTotal;
        uint256 restTotal;
    }
    struct MorgageStats {
        uint256 mortgage;
        uint256 freezeMortgage;
        uint256 relieveMortgage;
        uint256 inviteUserCount;
        uint256 inviteUserReward;
        uint256 applyRelieveTime;
        uint256 handleRelieveTime;
    }
    mapping(address => User) public users;
    mapping(address => uint256) public userIndex;

    User[] public userList;

    event addUser(address _userAddr);
    event updateUser(string _avatar, string _email, uint256 _isOnline);

    address _restCAddr;
    address _orderCAddr;
    address _recordCAddr;
    address _appealCAddr;

    modifier onlyAuthFromAddr() {
        require(_restCAddr != address(0), "Invalid address call rest");
        require(_orderCAddr != address(0), "Invalid address call order");
        require(_recordCAddr != address(0), "Invalid address call record");
        require(_appealCAddr != address(0), "Invalid address call appeal");
        _;
    }

    function authFromContract(
        address _fromRest,
        address _fromOrder,
        address _fromRecord,
        address _fromAppeal
    ) external {
        require(_restCAddr == address(0), "rest address has Auth");
        require(_orderCAddr == address(0), "order address has Auth");
        require(_recordCAddr == address(0), "record address has Auth");
        require(_appealCAddr == address(0), "appeal address has Auth");
        _restCAddr = _fromRest;
        _orderCAddr = _fromOrder;
        _recordCAddr = _fromRecord;
        _appealCAddr = _fromAppeal;
    }

    modifier onlyMemberOf() {
        require(users[msg.sender].userAddr != address(0), "has no permission");
        _;
    }

    function _insert(address _addr) internal {
        require(_addr != address(0), "UserStorage: addr null is not allowed");
        require(
            users[_addr].userAddr == address(0),
            "UserStorage: current User exist"
        );

        TradeStats memory tradeStats = TradeStats({
            tradeTotal: 0,
            restTotal: 0
        });
        MorgageStats memory morgageStats = MorgageStats({
            mortgage: 0,
            freezeMortgage: 0,
            relieveMortgage: 0,
            inviteUserCount: 0,
            inviteUserReward: 0,
            applyRelieveTime: 0,
            handleRelieveTime: 0
        });

        User memory u = User({
            userAddr: _addr,
            avatar: "",
            email: "",
            isOnline: 1,
            userFlag: 0,
            credit: 0,
            regTime: block.timestamp,
            tradeStats: tradeStats,
            morgageStats: morgageStats
        });
        users[_addr] = u;

        userList.push(u);
        userIndex[_addr] = userList.length - 1;
        emit addUser(_addr);
    }

    function _updateInfo(
        address _addr,
        string memory _avatar,
        string memory _email,
        uint256 _isOnline
    ) internal {
        require(_addr != address(0), "UserStorage: _addr null is not allowed");
        require(
            users[_addr].userAddr != address(0),
            "UserStorage: current User not exist"
        );

        User memory u = users[_addr];
        if (bytes(_avatar).length != 0) {
            u.avatar = _avatar;
        }
        if (bytes(_email).length != 0) {
            u.email = _email;
        }

        if (_isOnline != uint256(0)) {
            u.isOnline = _isOnline;
        }

        users[_addr] = u;
        userList[userIndex[_addr]] = u;
    }

    function _updateTradeStats(
        address _addr,
        TradeStats memory _tradeStats,
        uint256 _credit
    ) internal {
        require(_addr != address(0), "UserStorage: _addr null is not allowed");
        require(
            users[_addr].userAddr != address(0),
            "UserStorage: current User not exist"
        );

        User memory u = users[_addr];

        u.credit = _credit;

        u.tradeStats.tradeTotal = _tradeStats.tradeTotal;

        u.tradeStats.restTotal = _tradeStats.restTotal;

        users[_addr] = u;
        userList[userIndex[_addr]] = u;
    }

    function _updateMorgageStats(
        address _addr,
        MorgageStats memory _morgageStats
    ) internal {
        require(_addr != address(0), "UserStorage: _addr null is not allowed");
        require(
            users[_addr].userAddr != address(0),
            "UserStorage: current User not exist"
        );

        User memory u = users[_addr];

        u.morgageStats.mortgage = _morgageStats.mortgage;
        u.morgageStats.freezeMortgage = _morgageStats.freezeMortgage;
        u.morgageStats.relieveMortgage = _morgageStats.relieveMortgage;
        u.morgageStats.inviteUserCount = _morgageStats.inviteUserCount;
        u.morgageStats.inviteUserReward = _morgageStats.inviteUserReward;
        u.morgageStats.applyRelieveTime = _morgageStats.applyRelieveTime;
        u.morgageStats.handleRelieveTime = _morgageStats.handleRelieveTime;

        users[_addr] = u;
        userList[userIndex[_addr]] = u;
    }

    function _search(address _addr) internal view returns (User memory user) {
        require(_addr != address(0), "UserStorage: _addr null is not allowed");
        require(
            users[_addr].userAddr != address(0),
            "UserStorage: current User not exist"
        );

        User memory a = users[_addr];
        return a;
    }

    function register() external {
        require(!isMemberOf());
        _insert(msg.sender);
    }

    function isMemberOf() public view returns (bool) {
        return (users[msg.sender].userAddr != address(0));
    }

    function updateInfo(
        string memory _avatar,
        string memory _email,
        uint256 _isOnline
    ) external onlyMemberOf {
        _updateInfo(msg.sender, _avatar, _email, _isOnline);
        emit updateUser(_avatar, _email, _isOnline);
    }

    function updateTradeStats(
        address _addr,
        TradeStats memory _tradeStats,
        uint256 _credit
    ) public onlyAuthFromAddr {
        require(
            msg.sender == _restCAddr ||
                msg.sender == _orderCAddr ||
                msg.sender == _appealCAddr ||
                msg.sender == _recordCAddr,
            "UserStorage:Invalid from contract address"
        );
        _updateTradeStats(_addr, _tradeStats, _credit);
    }

    function updateMorgageStats(
        address _addr,
        MorgageStats memory _morgageStats
    ) public onlyAuthFromAddr {
        require(
            msg.sender == _recordCAddr,
            "UserStorage:Invalid from contract address"
        );
        _updateMorgageStats(_addr, _morgageStats);
    }

    function updateUserRole(address _addr, uint256 _userFlag)
        public
        onlyAuthFromAddr
    {
        require(
            msg.sender == _recordCAddr,
            "UserStorage:Invalid from contract address"
        );
        require(_addr != address(0), "UserStorage: _addr null is not allowed");
        require(
            users[_addr].userAddr != address(0),
            "UserStorage: current User not exist"
        );
        require(_userFlag >= 0, "UserStorage: Invalid userFlag 1");
        require(_userFlag <= 3, "UserStorage: Invalid userFlag 3");

        User memory u = users[_addr];
        u.userFlag = _userFlag;
        users[_addr] = u;
        userList[userIndex[_addr]] = u;
    }

    function searchUser(address _addr)
        external
        view
        returns (User memory user)
    {
        return _search(_addr);
    }

    function searchUserList() external view returns (User[] memory) {
        return userList;
    }

    function searchWitnessList(uint256 _userFlag)
        external
        view
        returns (User[] memory)
    {
        User[] memory _resultList = new User[](userList.length);
        for (uint256 i = 0; i < userList.length; i++) {
            User memory _u = userList[i];
            if (_u.userFlag == _userFlag) {
                _resultList[i] = _u;
            }
        }
        return _resultList;
    }
}

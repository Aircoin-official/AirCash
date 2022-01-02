// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./RecordInterface.sol";
import "./UserStorage.sol";
import "./OrderStorage.sol";

interface TokenTransfer {
    function transfer(address recipient, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);
}

contract RecordStorage is Ownable {
    mapping(string => address) coinTypeMaping;
    string[] coinTypeList = ["USDT", "USDC", "BUSD"];

    uint256 merchantNeedCount = 10000000000 * (10**18);
    uint256 witnessNeedCount = 100000000000 * (10**18);
    uint256 congressNeedCount = 1000000000000 * (10**18);
    string[] appealFeeCoinTypeList = ["AIR"];
    uint256 appealFee = 1000000 * (10**18);
    uint256 appealFeeFinal = 10000000 * (10**18);
    uint256 canWithdrawToTime = 28;
    uint256 subWitFee = 2000000 * (10**18);
    uint256 subWitCredit = 10;
    uint256 witnessHandleReward = 1000000 * (10**18);
    uint256 observerHandleReward = 10000000 * (10**18);
    uint256 witnessHandleCredit = 1;
    uint256 observerHandleCredit = 1;
    bool openTrade = false;
    uint256 tradeCredit = 1;
    uint256 subTCredit = 10;

    mapping(address => uint256) witnessFlag;
    mapping(address => uint256) congressFlag;

    function setWitnessFlag(address _addr, uint256 _flag) public onlyOwner {
        witnessFlag[_addr] = _flag;
        if (_flag == 1) {
            uint256 _amt = availableTotal[_addr]["AIR"];
            require(_amt >= witnessNeedCount, "coin not enough");
            _userStorage.updateUserRole(_addr, 1);
        } else {
            _userStorage.updateUserRole(_addr, 0);
        }
    }

    function getWitnessFlag(address _addr) public view returns (uint256) {
        return witnessFlag[_addr];
    }

    function setCongressFlag(address _addr, uint256 _flag) public onlyOwner {
        congressFlag[_addr] = _flag;
        if (_flag == 1) {
            uint256 _amt = availableTotal[_addr]["AIR"];
            require(_amt >= congressNeedCount, "coin not enough");
            _userStorage.updateUserRole(_addr, 2);
        } else {
            _userStorage.updateUserRole(_addr, 0);
        }
    }

    function getCongressFlag(address _addr) public view returns (uint256) {
        return congressFlag[_addr];
    }

    function setCoinType(string[] memory _coinTypeList) public onlyOwner {
        coinTypeList = _coinTypeList;
    }

    function getCoinType() public view returns (string[] memory) {
        return coinTypeList;
    }

    function setCoinTypeMapping(string memory _coinType, address _coinTypeAddr)
        public
        onlyOwner
    {
        coinTypeMaping[_coinType] = _coinTypeAddr;
    }

    function getCoinTypeMapping(string memory _coinType)
        public
        view
        returns (address)
    {
        return coinTypeMaping[_coinType];
    }

    function setMerchantNeedCount(uint256 _count) public onlyOwner {
        merchantNeedCount = _count * (10**18);
    }

    function getMerchantNeedCount() public view returns (uint256) {
        return merchantNeedCount;
    }

    function setWitnessNeedCount(uint256 _count) public onlyOwner {
        witnessNeedCount = _count * (10**18);
    }

    function getWitnessNeedCount() public view returns (uint256) {
        return witnessNeedCount;
    }

    function setCongressNeedCount(uint256 _count) public onlyOwner {
        congressNeedCount = _count * (10**18);
    }

    function getCongressNeedCount() public view returns (uint256) {
        return congressNeedCount;
    }

    function setAppealFee(uint256 _count) public onlyOwner {
        appealFee = _count * (10**18);
    }

    function getAppealFee() public view returns (uint256) {
        return appealFee;
    }

    function setAppealFeeFinal(uint256 _count) public onlyOwner {
        appealFeeFinal = _count * (10**18);
    }

    function getAppealFeeFinal() public view returns (uint256) {
        return appealFeeFinal;
    }

    function setCanWithdrawToTime(uint256 _days) public onlyOwner {
        canWithdrawToTime = _days;
    }

    function getCanWithdrawToTime() public view returns (uint256) {
        return canWithdrawToTime;
    }

    function setAppealFeeCoinTypeList(string[] memory _list) public onlyOwner {
        appealFeeCoinTypeList = _list;
    }

    function getAppealFeeCoinTypeList() public view returns (string[] memory) {
        return appealFeeCoinTypeList;
    }

    function setSubWitFee(uint256 _c) public onlyOwner {
        subWitFee = _c * (10**18);
    }

    function getSubWitFee() public view returns (uint256) {
        return subWitFee;
    }

    function setSubWitCredit(uint256 _c) public onlyOwner {
        subWitCredit = _c;
    }

    function getSubWitCredit() public view returns (uint256) {
        return subWitCredit;
    }

    function setWitnessHandleReward(uint256 _c) public onlyOwner {
        witnessHandleReward = _c * (10**18);
    }

    function getWitnessHandleReward() public view returns (uint256) {
        return witnessHandleReward;
    }

    function setObserverHandleReward(uint256 _c) public onlyOwner {
        observerHandleReward = _c * (10**18);
    }

    function getObserverHandleReward() public view returns (uint256) {
        return observerHandleReward;
    }

    function setWitnessHandleCredit(uint256 _c) public onlyOwner {
        witnessHandleCredit = _c;
    }

    function getWitnessHandleCredit() public view returns (uint256) {
        return witnessHandleCredit;
    }

    function setObserverHandleCredit(uint256 _c) public onlyOwner {
        observerHandleCredit = _c;
    }

    function getObserverHandleCredit() public view returns (uint256) {
        return observerHandleCredit;
    }

    function setOpenTrade(bool _c) public onlyOwner {
        openTrade = _c;
    }

    function getOpenTrade() public view returns (bool) {
        return openTrade;
    }

    function setTradeCredit(uint256 _c) public onlyOwner {
        tradeCredit = _c;
    }

    function getTradeCredit() public view returns (uint256) {
        return tradeCredit;
    }

    function setSubTCredit(uint256 _c) public onlyOwner {
        subTCredit = _c;
    }

    function getSubTCredit() public view returns (uint256) {
        return subTCredit;
    }

    function punishPerson(
        address _from,
        address _to,
        uint256 _count
    ) public onlyOwner {
        require(_from != address(0), "Invalid from");
        require(_to != address(0), "Invalid to");
        UserStorage.User memory _user = _userStorage.searchUser(_from);
        require(
            _user.userFlag == 1 || _user.userFlag == 2,
            "can't punish this person"
        );

        require(
            availableTotal[_from]["AIR"] >= _count,
            "user balance not enough"
        );
        availableTotal[_from]["AIR"] = SafeMath.sub(
            availableTotal[_from]["AIR"],
            _count
        );
        availableTotal[_to]["AIR"] = SafeMath.add(
            availableTotal[_to]["AIR"],
            _count
        );
    }

    UserInterface private _userStorage;
    OrderInterface private _orderStorage;
    struct Record {
        uint256 recordNo;
        address userAddr;
        string tradeHash;
        string coinType;
        uint256 hostCount;
        uint256 hostStatus;
        uint256 hostType;
        uint256 hostDirection;
        uint256 hostTime;
        uint256 updateTime;
    }

    mapping(uint256 => Record) public records;
    mapping(uint256 => uint256) public recordIndex;

    Record[] public recordList;
    uint256 subFromDraing = 0;

    mapping(address => mapping(string => uint256)) public availableTotal;

    mapping(address => mapping(string => uint256)) public frozenTotal;

    mapping(address => mapping(string => uint256)) public unfrozenTotal;

    mapping(address => uint256) lastWithdrawTime;

    mapping(address => mapping(uint256 => uint256)) lastWithdrawAmount;

    mapping(address => mapping(string => uint256)) public withdrawingTotal;

    mapping(address => mapping(uint256 => uint256)) orderSubFrozenList;

    constructor(
        address _usdtAddress,
        address _usdcAddress,
        address _busdAddress,
        address _airAddress
    ) {
        coinTypeMaping["USDT"] = _usdtAddress;
        coinTypeMaping["USDC"] = _usdcAddress;
        coinTypeMaping["BUSD"] = _busdAddress;
        coinTypeMaping["AIR"] = _airAddress;
    }

    function setERC20Address(string memory _coinType)
        public
        view
        returns (TokenTransfer)
    {
        require(bytes(_coinType).length != 0, "Invalid coin type");
        address _remoteAddr = coinTypeMaping[_coinType];

        require(_remoteAddr != address(0), "Invalid coin type");

        TokenTransfer _tokenTransfer = TokenTransfer(_remoteAddr);
        return _tokenTransfer;
    }

    event RecordAdd(
        uint256 _recordNo,
        address _addr,
        string _tradeHash,
        string _coinType,
        uint256 _hostCount,
        uint256 _hostStatus,
        uint256 _hostType,
        uint256 _hostDirection
    );
    event RecordApplyUnfrozen(address _addr, uint256 _amt);
    event UnfrozenTotalTransfer(
        address _addr,
        string _coinType,
        uint256 _lastAmount
    );
    event RecordUpdate(
        address _addr,
        uint256 _recordNo,
        string _hash,
        uint256 _hostStatus
    );

    address _userAddr;
    address _restCAddr;
    address _orderCAddr;
    address _appealCAddr;

    modifier onlyAuthFromAddr() {
        require(_userAddr != address(0), "Invalid address call user");
        require(_restCAddr != address(0), "Invalid address call rest");
        require(_orderCAddr != address(0), "Invalid address call order");
        require(_appealCAddr != address(0), "Invalid address call appeal");
        _;
    }

    function authFromContract(
        address _fromUser,
        address _fromRest,
        address _fromOrder,
        address _fromAppeal
    ) external {
        require(_userAddr == address(0), "rest address has Auth");
        require(_restCAddr == address(0), "rest address has Auth");
        require(_orderCAddr == address(0), "order address has Auth");
        require(_appealCAddr == address(0), "appeal address has Auth");
        _userAddr = _fromUser;
        _restCAddr = _fromRest;
        _orderCAddr = _fromOrder;
        _appealCAddr = _fromAppeal;
        _userStorage = UserInterface(_userAddr);
        _orderStorage = OrderInterface(_orderCAddr);
    }

    function _insert(
        address _addr,
        string memory _tradeHash,
        string memory _coinType,
        uint256 _hostCount,
        uint256 _hostStatus,
        uint256 _hostType,
        uint256 _hostDirection
    ) internal returns (uint256 recordNo) {
        require(_addr != address(0), "address null is not allowed");
        require(bytes(_coinType).length != 0, "coinType null is not allowed");
        require(_hostCount != uint256(0), "hostCount null is not allowed");
        require(_hostType != uint256(0), "hostType null is not allowed");
        require(
            _hostDirection != uint256(0),
            "hostDirection null is not allowed"
        );

        uint256 _recordNo = block.timestamp;
        Record memory _record = Record({
            recordNo: _recordNo,
            userAddr: _addr,
            tradeHash: _tradeHash,
            coinType: _coinType,
            hostCount: _hostCount,
            hostStatus: _hostStatus,
            hostType: _hostType,
            hostDirection: _hostDirection,
            hostTime: block.timestamp,
            updateTime: 0
        });

        records[_recordNo] = _record;

        recordList.push(_record);
        recordIndex[_recordNo] = recordList.length - 1;
        emit RecordAdd(
            _recordNo,
            _addr,
            _tradeHash,
            _coinType,
            _hostCount,
            _hostStatus,
            _hostType,
            _hostDirection
        );
        return _recordNo;
    }

    function tokenEscrow(string memory _coinType, uint256 _amt) external {
        require(_amt > 0, "Invalid transfer amount");
        require(
            availableTotal[msg.sender][_coinType] + _amt >
                availableTotal[msg.sender][_coinType],
            "Invalid transfer amount"
        );

        availableTotal[msg.sender][_coinType] = SafeMath.add(
            availableTotal[msg.sender][_coinType],
            _amt
        );

        uint256 _hostType = 1;
        if (
            keccak256(abi.encodePacked(_coinType)) ==
            keccak256(abi.encodePacked("AIR"))
        ) {
            _hostType = 3;
            UserStorage.User memory _user = _userStorage.searchUser(msg.sender);
            UserStorage.MorgageStats memory _morgageStats = _user.morgageStats;
            _morgageStats.mortgage = SafeMath.add(_morgageStats.mortgage, _amt);
            _userStorage.updateMorgageStats(msg.sender, _morgageStats);

            if (
                _user.userFlag == 0 &&
                _morgageStats.mortgage >= merchantNeedCount
            ) {
                _userStorage.updateUserRole(msg.sender, 3);
            }
        }
        _insert(msg.sender, "", _coinType, _amt, 2, _hostType, 1);

        TokenTransfer _tokenTransfer = setERC20Address(_coinType);
        _tokenTransfer.transferFrom(msg.sender, address(this), _amt);
    }

    function addRecord(
        address _addr,
        string memory _tradeHash,
        string memory _coinType,
        uint256 _hostCount,
        uint256 _hostStatus,
        uint256 _hostType,
        uint256 _hostDirection
    ) public onlyAuthFromAddr {
        require(
            msg.sender == _restCAddr || msg.sender == _orderCAddr,
            "RedocrdStorage:Invalid from contract address"
        );

        frozenTotal[_addr][_coinType] = SafeMath.add(
            frozenTotal[_addr][_coinType],
            _hostCount
        );
        _insert(
            _addr,
            _tradeHash,
            _coinType,
            _hostCount,
            _hostStatus,
            _hostType,
            _hostDirection
        );
    }

    function addAvailableTotal(
        address _addr,
        string memory _coinType,
        uint256 _amt
    ) public onlyAuthFromAddr {
        require(
            msg.sender == _restCAddr || msg.sender == _orderCAddr,
            "Invalid address"
        );
        require(_amt > 0, "Invalid transfer amount");
        uint256 _aBalance = getErcBalance(_coinType, address(this));
        require(_aBalance >= _amt, "balance not enough");
        require(frozenTotal[_addr][_coinType] >= _amt, "Invalid amount");
        require(
            SafeMath.sub(frozenTotal[_addr][_coinType], _amt) <=
                frozenTotal[_addr][_coinType],
            "Invalid amount"
        );
        frozenTotal[_addr][_coinType] = SafeMath.sub(
            frozenTotal[_addr][_coinType],
            _amt
        );

        TokenTransfer _tokenTransfer = setERC20Address(_coinType);
        _tokenTransfer.transfer(_addr, _amt);
    }

    function getAvailableTotal(address _addr, string memory _coinType)
        public
        view
        returns (uint256)
    {
        return availableTotal[_addr][_coinType];
    }

    function subFrozenTotal(uint256 _orderNo, address _addr)
        public
        onlyAuthFromAddr
    {
        require(
            msg.sender == _orderCAddr || msg.sender == _appealCAddr,
            "Invalid from contract address"
        );
        OrderStorage.Order memory _order = _orderStorage.searchOrder(_orderNo);
        require(_order.orderNo != uint256(0), "order not exist");
        address _seller = _order.orderDetail.sellerAddr;
        string memory _coinType = _order.orderDetail.coinType;

        uint256 _subAmount = orderSubFrozenList[_seller][_orderNo];
        require(_subAmount == 0, "order not exist");

        uint256 _frozen = frozenTotal[_seller][_coinType];
        uint256 _orderCount = _order.coinCount;
        require(_frozen >= _orderCount, "Invalid amount");
        require(
            SafeMath.sub(_frozen, _orderCount) <= _frozen,
            "Invalid amount 2"
        );

        frozenTotal[_seller][_coinType] = SafeMath.sub(_frozen, _orderCount);
        orderSubFrozenList[_seller][_orderNo] = _orderCount;

        TokenTransfer _tokenTransfer = setERC20Address(_coinType);
        _tokenTransfer.transfer(_addr, _orderCount);
    }

    function subAvaAppeal(
        address _from,
        address _to,
        AppealStorage.Appeal memory _al,
        uint256 _amt,
        uint256 _t,
        uint256 _self
    ) public onlyAuthFromAddr {
        require(
            msg.sender == _appealCAddr,
            "RedocrdStorage:Invalid from contract address"
        );

        uint256 _available = getAvailableTotal(_from, "AIR");
        uint256 _need = 0;
        address _opt = _t == 1 ? _al.witness : _al.detail.observerAddr;
        if (_available >= _amt) {
            _need = _amt;
        } else {
            _need = _available;
        }

        if (
            (_t == 1 && _self == 0) ||
            (_t == 2 && _al.detail.finalAppealAddr != _from)
        ) {
            availableTotal[_from]["AIR"] = SafeMath.sub(
                availableTotal[_from]["AIR"],
                _need
            );
            availableTotal[_to]["AIR"] = SafeMath.add(
                availableTotal[_to]["AIR"],
                _need
            );
        }

        availableTotal[_opt]["AIR"] = SafeMath.add(
            availableTotal[_opt]["AIR"],
            _amt
        );
        chanRole(_from);

        UserStorage.User memory _user = _userStorage.searchUser(_opt);
        if (_t == 1) {
            _user.credit = _user.credit + witnessHandleCredit;
        } else if (_t == 2) {
            _user.credit = _user.credit + observerHandleCredit;
        }
        UserStorage.TradeStats memory _tradeStats = _user.tradeStats;
        _userStorage.updateTradeStats(_opt, _tradeStats, _user.credit);
    }

    function subWitnessAvailable(address _addr) public onlyAuthFromAddr {
        require(
            msg.sender == _appealCAddr,
            "RedocrdStorage:Invalid from contract address"
        );
        require(_addr != address(0), "witness address is null");
        uint256 _availableTotal = availableTotal[_addr]["AIR"];
        uint256 _need = 0;
        if (_availableTotal >= subWitFee) {
            _need = subWitFee;
            availableTotal[_addr]["AIR"] = SafeMath.sub(_availableTotal, _need);
        } else {
            availableTotal[_addr]["AIR"] = 0;

            uint256 _draing = withdrawingTotal[_addr]["AIR"];
            if (SafeMath.add(_availableTotal, _draing) >= subWitFee) {
                _need = subWitFee;
                subFromDraing = subWitFee - _availableTotal - _draing;
                withdrawingTotal[_addr]["AIR"] = SafeMath.sub(
                    withdrawingTotal[_addr]["AIR"],
                    subFromDraing
                );
            } else {
                _need = SafeMath.add(
                    withdrawingTotal[_addr]["AIR"],
                    availableTotal[_addr]["AIR"]
                );
                withdrawingTotal[_addr]["AIR"] = 0;
            }
        }
        chanRole(_addr);

        UserStorage.User memory _user = _userStorage.searchUser(_addr);
        _user.credit = _user.credit >= subWitCredit
            ? (_user.credit - subWitCredit)
            : 0;
        UserStorage.TradeStats memory _tradeStats = _user.tradeStats;
        _userStorage.updateTradeStats(_addr, _tradeStats, _user.credit);

        TokenTransfer _tokenTransfer = setERC20Address("AIR");
        _tokenTransfer.transfer(owner(), _need);
    }

    function getFrozenTotal(address _addr, string memory _coinType)
        public
        view
        returns (uint256)
    {
        return frozenTotal[_addr][_coinType];
    }

    function applyUnfrozen(uint256 _amt) public returns (uint256) {
        string memory _coinType = "AIR";
        require(_amt > 0, "Invalid transfer amount");
        require(
            availableTotal[msg.sender][_coinType] >= _amt,
            "Invalid amount"
        );
        require(
            SafeMath.sub(availableTotal[msg.sender][_coinType], _amt) <
                availableTotal[msg.sender][_coinType],
            "Invalid amount 2"
        );

        lastWithdrawTime[msg.sender] = block.timestamp;
        lastWithdrawAmount[msg.sender][lastWithdrawTime[msg.sender]] = _amt;
        availableTotal[msg.sender][_coinType] = SafeMath.sub(
            availableTotal[msg.sender][_coinType],
            _amt
        );
        withdrawingTotal[msg.sender][_coinType] = SafeMath.add(
            withdrawingTotal[msg.sender][_coinType],
            _amt
        );

        chanRole(msg.sender);

        _insert(msg.sender, "", _coinType, _amt, 3, 3, 2);

        emit RecordApplyUnfrozen(msg.sender, _amt);

        return getAvailableTotal(msg.sender, _coinType);
    }

    function chanRole(address _addr) internal {
        uint256 _avail = availableTotal[_addr]["AIR"];

        UserStorage.User memory _user = _userStorage.searchUser(_addr);
        UserStorage.MorgageStats memory _morgageStats = _user.morgageStats;
        _morgageStats.mortgage = _avail;

        _userStorage.updateMorgageStats(_addr, _morgageStats);

        if (
            _user.userFlag == 2 &&
            _avail < congressNeedCount &&
            _avail >= merchantNeedCount
        ) {
            _userStorage.updateUserRole(_addr, 3);
        }

        if (
            _user.userFlag == 1 &&
            _avail < witnessNeedCount &&
            _avail >= merchantNeedCount
        ) {
            _userStorage.updateUserRole(_addr, 3);
        }

        if (_avail < merchantNeedCount) {
            _userStorage.updateUserRole(_addr, 0);
        }
    }

    function applyWithdraw(uint256 _recordNo) public {
        Record memory _record = records[_recordNo];

        require(_record.recordNo != uint256(0), "record not exist");
        require(_record.userAddr == msg.sender, "record user not exist");

        require(_record.hostStatus == 3, "status error");

        require(
            withdrawingTotal[msg.sender]["AIR"] >= _record.hostCount,
            "balance not enough"
        );

        require(
            block.timestamp >= (_record.hostTime + canWithdrawToTime * 1 days),
            "can't withdraw"
        );

        withdrawingTotal[msg.sender]["AIR"] = SafeMath.sub(
            withdrawingTotal[msg.sender]["AIR"],
            _record.hostCount
        );
        unfrozenTotal[msg.sender]["AIR"] = SafeMath.add(
            unfrozenTotal[msg.sender]["AIR"],
            _record.hostCount
        );

        _record.hostCount = SafeMath.sub(_record.hostCount, subFromDraing);
        _record.hostStatus = 4;
        _record.updateTime = block.timestamp;
        records[_recordNo] = _record;
        recordList[recordIndex[_recordNo]] = _record;
        emit RecordUpdate(msg.sender, _recordNo, _record.tradeHash, 4);

        TokenTransfer _tokenTransfer = setERC20Address("AIR");
        _tokenTransfer.transfer(msg.sender, _record.hostCount);
    }

    function unfrozenTotalSearch(address _addr, string memory _coinType)
        public
        view
        returns (uint256)
    {
        require(_addr != address(0), "user address is null");

        return unfrozenTotal[_addr][_coinType];
    }

    function getUnfrozenTotal(address _addr, string memory _coinType)
        external
        view
        returns (uint256)
    {
        return unfrozenTotal[_addr][_coinType];
    }

    function getWithdrawingTotal(address _addr, string memory _coinType)
        public
        view
        returns (uint256)
    {
        return withdrawingTotal[_addr][_coinType];
    }

    function getErcBalance(string memory _coinType, address _addr)
        public
        view
        returns (uint256)
    {
        TokenTransfer _tokenTransfer = setERC20Address(_coinType);
        return _tokenTransfer.balanceOf(_addr);
    }

    function _updateInfo(
        address _addr,
        uint256 _recordNo,
        string memory _hash,
        uint256 _hostStatus
    ) internal returns (bool) {
        Record memory _record = records[_recordNo];
        require(_record.userAddr == _addr, "record not exist");
        require(_hostStatus == 1 || _hostStatus == 2, "invalid hostStatus");

        if (_hostStatus != uint256(0)) {
            _record.hostStatus = _hostStatus;
        }
        if (bytes(_hash).length != 0) {
            _record.tradeHash = _hash;
        }

        _record.updateTime = block.timestamp;
        records[_recordNo] = _record;
        recordList[recordIndex[_recordNo]] = _record;
        emit RecordUpdate(_addr, _recordNo, _hash, _hostStatus);
        return true;
    }

    function updateInfo(
        address _addr,
        uint256 _recordNo,
        string memory _hash,
        uint256 _hostStatus
    ) external returns (bool) {
        return _updateInfo(_addr, _recordNo, _hash, _hostStatus);
    }

    function searchRecord(uint256 _recordNo)
        external
        view
        returns (Record memory record)
    {
        return records[_recordNo];
    }

    function searchRecordList() external view returns (Record[] memory) {
        return recordList;
    }
}

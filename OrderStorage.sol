// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./RecordInterface.sol";
import "./RestStorage.sol";
import "./UserStorage.sol";
import "./RecordStorage.sol";
import "./AppealStorage.sol";

contract OrderStorage is Ownable {
    RestStorage private _restStorage;
    RecordInterface private _recordStorage;
    UserInterface private _userStorage;
    AppealInterface private _appealS;
    address recordAddress;

    struct Order {
        address userAddr;
        uint256 orderNo;
        uint256 restNo;
        uint256 coinCount;
        uint256 orderAmount;
        uint256 payType;
        string currencyType;
        uint256 orderType;
        uint256 orderStatus;
        OrderDetail orderDetail;
    }
    struct OrderDetail {
        address buyerAddr;
        address sellerAddr;
        string coinType;
        uint256 price;
        uint256 tradeTime;
        uint256 updateTime;
        string tradeHash;
        uint256 tradeFee;
    }

    mapping(uint256 => Order) private orders;
    mapping(uint256 => uint256) private orderIndex;

    Order[] private orderList;

    mapping(address => mapping(uint256 => uint256)) orderFrozenTotal;

    uint256 cancelOrderTime = 30;

    function setCancelOrderTime(uint256 _count) public onlyOwner {
        cancelOrderTime = _count;
    }

    function getCancelOrderTime() public view returns (uint256) {
        return cancelOrderTime;
    }

    event OrderAdd(
        uint256 _orderNo,
        uint256 _restNo,
        uint256 _coinCount,
        uint256 _tradeFee,
        uint256 _orderAmount,
        uint256 _payType,
        uint256 _orderType,
        address _buyerAddr,
        address _sellerAddr
    );
    event OrderUpdateHash(uint256 _orderNo, string _tradeHash);
    event OrderPaidMoney(uint256 _orderNo);
    event OrderConfirmCollect(uint256 _orderNo);
    event OrderCancel(uint256 _orderNo);
    event OrderUpdateStatus(uint256 _orderNo, uint256 _orderStatus);

    constructor(
        address _recordAddr,
        address _restAddr,
        address _userAddr
    ) {
        _recordStorage = RecordInterface(_recordAddr);
        _restStorage = RestStorage(_restAddr);
        _userStorage = UserInterface(_userAddr);
        recordAddress = _recordAddr;
    }

    address _appealCAddr;

    modifier onlyAuthFromAddr() {
        require(_appealCAddr != address(0), "Invalid address call order");
        _;
    }

    function authFromContract(address _fromAppeal) external {
        require(_appealCAddr == address(0), "appeal address has Auth");
        _appealCAddr = _fromAppeal;
        _appealS = AppealInterface(_appealCAddr);
    }

    modifier onlyBuyer(uint256 _orderNo) {
        require(_orderNo != uint256(0), "orderNo null is not allowed");
        require(
            orders[_orderNo].orderDetail.buyerAddr == msg.sender,
            "Only buyer can call"
        );
        _;
    }

    modifier onlySeller(uint256 _orderNo) {
        require(_orderNo != uint256(0), "orderNo null is not allowed");
        require(
            orders[_orderNo].orderDetail.sellerAddr == msg.sender,
            "Only seller can call"
        );
        _;
    }

    modifier onlyBuyerOrSeller(uint256 _orderNo) {
        require(_orderNo != uint256(0), "orderNo null is not allowed");
        require(
            orders[_orderNo].orderDetail.sellerAddr == msg.sender ||
                orders[_orderNo].orderDetail.buyerAddr == msg.sender,
            "Only buyer or seller can call"
        );
        _;
    }

    function _checkParam(
        uint256 _restNo,
        uint256 _coinCount,
        uint256 _orderAmount,
        uint256 _payType
    ) internal pure {
        require(
            _restNo != uint256(0),
            "OrderStorage: restNo null is not allowed"
        );
        require(_coinCount > 0, "OrderStorage: coinCount null is not allowed");
        require(
            _orderAmount > 0,
            "OrderStorage: orderAmount null is not allowed"
        );
        require(
            _payType != uint256(0),
            "OrderStorage: payType null is not allowed"
        );
    }

    function _insert(
        uint256 _restNo,
        uint256 _coinCount,
        uint256 _tradeFee,
        uint256 _orderAmount,
        uint256 _payType,
        uint256 _orderType,
        address _buyerAddr,
        address _sellerAddr
    ) internal returns (uint256 restNo) {
        _checkParam(_restNo, _coinCount, _orderAmount, _payType);

        RestStorage.Rest memory _rest = _restStorage.searchRest(_restNo);
        require(_rest.userAddr != address(0), "rest not exist");
        OrderDetail memory _orderDetail = OrderDetail({
            buyerAddr: _buyerAddr,
            sellerAddr: _sellerAddr,
            coinType: _rest.coinType,
            price: _rest.price,
            tradeTime: block.timestamp,
            updateTime: 0,
            tradeHash: "",
            tradeFee: _tradeFee
        });

        uint256 _orderNo = block.timestamp;
        Order memory order = Order({
            userAddr: msg.sender,
            orderNo: _orderNo,
            restNo: _restNo,
            coinCount: _coinCount,
            orderAmount: _orderAmount,
            payType: _payType,
            currencyType: _rest.currencyType,
            orderType: _orderType,
            orderStatus: 1,
            orderDetail: _orderDetail
        });

        orders[_orderNo] = order;

        orderList.push(order);
        orderIndex[_orderNo] = orderList.length - 1;

        if (_orderType == 2) {
            orderFrozenTotal[msg.sender][_orderNo] = _coinCount;
        } else if (_orderType == 1) {
            orderFrozenTotal[_rest.userAddr][_orderNo] = _coinCount;
        }

        emit OrderAdd(
            _orderNo,
            _restNo,
            _coinCount,
            _tradeFee,
            _orderAmount,
            _payType,
            _orderType,
            _buyerAddr,
            _sellerAddr
        );

        return _orderNo;
    }

    function addBuyOrder(
        uint256 _restNo,
        uint256 _coinCount,
        uint256 _orderAmount,
        uint256 _payType
    ) external {
        RestStorage.Rest memory _rest = _restStorage.searchRest(_restNo);
        require(_rest.userAddr != msg.sender, "rest not exist");
        require(_rest.restType == 2, "sell rest not exist");
        require(_coinCount > 0 && _orderAmount > 0, "coin count error");
        require(_rest.restStatus == 1, "rest status error");
        UserStorage.User memory _currentUser = _userStorage.searchUser(
            msg.sender
        );

        require(
            _currentUser.userFlag != 1 && _currentUser.userFlag != 2,
            "invalid user"
        );

        uint256 _restFrozen = _restStorage.getRestFrozenTotal(
            _rest.userAddr,
            _restNo
        );
        require(_restFrozen >= _coinCount, "coin not enough");

        uint256 _amo = SafeMath.mul(_rest.price, _coinCount);
        require(
            _amo >= _rest.restDetail.limitAmountFrom &&
                _amo <= _rest.restDetail.limitAmountTo,
            "amount error"
        );
        require(
            _currentUser.credit >= _rest.restDetail.limitMinCredit,
            "credit error"
        );
        require(
            _currentUser.morgageStats.mortgage >=
                _rest.restDetail.limitMinMortgage,
            "mortgage error"
        );

        _restStorage.updateRestFinishCount(_restNo, _coinCount);
        _insert(
            _restNo,
            _coinCount,
            0,
            _orderAmount,
            _payType,
            1,
            msg.sender,
            _rest.userAddr
        );
    }

    function addSellOrder(
        uint256 _restNo,
        uint256 _coinCount,
        uint256 _tradeFee,
        uint256 _orderAmount,
        uint256 _payType
    ) external {
        RestStorage.Rest memory _rest = _restStorage.searchRest(_restNo);
        require(_rest.userAddr != msg.sender, "rest not exist");
        require(_rest.restType == 1, "buy rest not exist");
        require(_coinCount > 0 && _tradeFee >= 0, "coin count error");
        require(_orderAmount > 0, "orderAmount error");
        require(_rest.restStatus == 1, "rest status error");

        uint256 _amo = SafeMath.mul(_rest.price, _coinCount);
        require(
            _amo >= _rest.restDetail.limitAmountFrom &&
                _amo <= _rest.restDetail.limitAmountTo,
            "amount error"
        );

        UserStorage.User memory _currentUser = _userStorage.searchUser(
            msg.sender
        );

        require(
            _currentUser.userFlag != 1 && _currentUser.userFlag != 2,
            "invalid user"
        );
        require(
            _currentUser.credit >= _rest.restDetail.limitMinCredit,
            "credit error"
        );
        require(
            _currentUser.morgageStats.mortgage >=
                _rest.restDetail.limitMinMortgage,
            "mortgage error"
        );

        uint256 _needSub = SafeMath.add(_coinCount, _tradeFee);

        _restStorage.updateRestFinishCount(_restNo, _coinCount);
        _insert(
            _restNo,
            _coinCount,
            _tradeFee,
            _orderAmount,
            _payType,
            2,
            _rest.userAddr,
            msg.sender
        );

        TokenTransfer _tokenTransfer = _recordStorage.setERC20Address(
            _rest.coinType
        );
        _tokenTransfer.transferFrom(msg.sender, recordAddress, _needSub);
        _recordStorage.addRecord(
            msg.sender,
            "",
            _rest.coinType,
            _coinCount,
            2,
            1,
            2
        );
    }

    function setPaidMoney(uint256 _orderNo)
        external
        onlyBuyer(_orderNo)
        returns (bool)
    {
        _updateOrderStatus(_orderNo, 2);
        emit OrderPaidMoney(_orderNo);
        return true;
    }

    function confirmCollect(uint256 _orderNo) external onlySeller(_orderNo) {
        require(
            _orderNo != uint256(0),
            "OrderStorage:orderNo null is not allowed"
        );
        Order memory _order = orders[_orderNo];
        require(_order.orderStatus == 2, "OrderStorage:Invalid order status");
        require(
            _order.orderDetail.buyerAddr != address(0),
            "OrderStorage:Invalid buyer address"
        );
        require(
            orderFrozenTotal[msg.sender][_orderNo] >= _order.coinCount,
            "OrderStorage:coin not enough"
        );

        _updateOrderStatus(_orderNo, 3);

        orderFrozenTotal[msg.sender][_orderNo] = 0;

        uint256 _rc = _recordStorage.getTradeCredit();
        UserStorage.User memory _user = _userStorage.searchUser(msg.sender);
        uint256 _credit = _user.credit + _rc;
        UserStorage.TradeStats memory _tradeStats = _user.tradeStats;
        _tradeStats.tradeTotal += 1;
        _userStorage.updateTradeStats(msg.sender, _tradeStats, _credit);

        UserStorage.User memory _user2 = _userStorage.searchUser(
            _order.orderDetail.buyerAddr
        );
        uint256 _credit2 = _user2.credit + _rc;
        UserStorage.TradeStats memory _tradeStats2 = _user2.tradeStats;
        _tradeStats2.tradeTotal += 1;
        _userStorage.updateTradeStats(
            _order.orderDetail.buyerAddr,
            _tradeStats2,
            _credit2
        );

        _recordStorage.subFrozenTotal(_orderNo, _order.orderDetail.buyerAddr);

        emit OrderConfirmCollect(_orderNo);
    }

    function cancelOrder(uint256 _orderNo)
        external
        onlyBuyerOrSeller(_orderNo)
        returns (bool)
    {
        Order memory _order = orders[_orderNo];
        require(
            _order.orderNo != uint256(0),
            "OrderStorage: current Order not exist"
        );

        require(_order.orderStatus == 1, "Can't cancel order");

        require(
            _order.orderDetail.tradeTime + cancelOrderTime * 1 minutes <
                block.timestamp,
            "30 minutes limit"
        );
        RestStorage.Rest memory _rest = _restStorage.searchRest(_order.restNo);

        if (_rest.restStatus == 4 || _rest.restStatus == 5) {
            orderFrozenTotal[_order.orderDetail.sellerAddr][_orderNo] = 0;

            _recordStorage.addAvailableTotal(
                _order.orderDetail.sellerAddr,
                _order.orderDetail.coinType,
                _order.coinCount
            );
        } else {
            if (_order.orderType == 2) {
                orderFrozenTotal[_order.orderDetail.sellerAddr][_orderNo] = 0;

                _recordStorage.addAvailableTotal(
                    _order.orderDetail.sellerAddr,
                    _order.orderDetail.coinType,
                    _order.coinCount
                );
            }

            _restStorage.addRestRemainCount(_order.restNo, _order.coinCount);
        }
        _updateOrderStatus(_orderNo, 4);
        emit OrderCancel(_orderNo);
        return true;
    }

    function takeCoin(uint256 _o) external onlyBuyerOrSeller(_o) {
        AppealStorage.Appeal memory _appeal = _appealS.searchAppeal(_o);
        require(
            block.timestamp - _appeal.detail.witnessHandleTime > 24 hours,
            "time error"
        );

        address _win;

        if (_appeal.user == _appeal.buyer) {
            if (_appeal.status == 2) {
                _win = _appeal.buyer;
            } else if (_appeal.status == 3) {
                _win = _appeal.seller;
            }
        } else {
            if (_appeal.status == 2) {
                _win = _appeal.seller;
            } else if (_appeal.status == 3) {
                _win = _appeal.buyer;
            }
        }
        require(_win == msg.sender, "opt error");

        _updateOrderStatus(_o, 5);
        orderFrozenTotal[_appeal.seller][_o] = 0;
        _recordStorage.subFrozenTotal(_o, msg.sender);
    }

    function _updateOrderStatus(uint256 _orderNo, uint256 _orderStatus)
        internal
        onlyBuyerOrSeller(_orderNo)
    {
        Order memory order = orders[_orderNo];
        require(
            order.orderNo != uint256(0),
            "OrderStorage: current Order not exist"
        );
        require(_orderStatus >= 1 && _orderStatus <= 5, "Invalid order status");

        if (_orderStatus == 2 && order.orderStatus != 1) {
            revert("Invalid order status 2");
        }
        if (_orderStatus == 3 && order.orderStatus != 2) {
            revert("Invalid order status 3");
        }
        if (_orderStatus == 4 && order.orderStatus != 1) {
            revert("Invalid order status 4");
        }
        if (
            _orderStatus == 5 &&
            order.orderStatus != 1 &&
            order.orderStatus != 2
        ) {
            revert("Invalid order status 5");
        }

        if (_orderStatus == 2) {
            require(
                order.orderDetail.buyerAddr == msg.sender,
                "only buyer call"
            );
        }
        if (_orderStatus == 3) {
            require(
                order.orderDetail.sellerAddr == msg.sender,
                "only seller call"
            );
        }
        order.orderStatus = _orderStatus;

        order.orderDetail.updateTime = block.timestamp;
        orders[_orderNo] = order;
        orderList[orderIndex[_orderNo]] = order;
        emit OrderUpdateStatus(_orderNo, _orderStatus);
    }

    function _search(uint256 _orderNo)
        internal
        view
        returns (Order memory order)
    {
        require(
            _orderNo != uint256(0),
            "OrderStorage: orderNo null is not allowed"
        );
        require(
            orders[_orderNo].orderNo != uint256(0),
            "OrderStorage: current Order not exist"
        );

        Order memory o = orders[_orderNo];
        return o;
    }

    function searchOrder(uint256 _orderNo)
        external
        view
        returns (Order memory order)
    {
        return _search(_orderNo);
    }

    function searchOrderList() external view returns (Order[] memory) {
        return orderList;
    }

    function searchMyOrderList() external view returns (Order[] memory) {
        Order[] memory resultList = new Order[](orderList.length);
        for (uint256 i = 0; i < orderList.length; i++) {
            Order memory _order = orderList[i];
            if (
                _order.orderDetail.buyerAddr == msg.sender ||
                _order.orderDetail.sellerAddr == msg.sender
            ) {
                resultList[i] = _order;
            }
        }
        return resultList;
    }

    function searchListByRest(uint256 _restNo)
        external
        view
        returns (Order[] memory)
    {
        Order[] memory resultList = new Order[](orderList.length);
        for (uint256 i = 0; i < orderList.length; i++) {
            Order memory _order = orderList[i];
            if (_order.restNo == _restNo) {
                resultList[i] = _order;
            }
        }
        return resultList;
    }
}

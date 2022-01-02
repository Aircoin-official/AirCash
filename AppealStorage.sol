// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./RecordInterface.sol";
import "./UserStorage.sol";

contract AppealStorage {
    OrderInterface private _oSt;
    RecordInterface private _rSt;
    UserInterface private _uSt;
    address recAddr;

    struct Appeal {
        address user;
        uint256 appealNo;
        uint256 orderNo;
        address witness;
        address buyer;
        address seller;
        uint256 mortgage;
        uint256 status;
        uint256 appealTime;
        uint256 witTakeTime;
        uint256 obTakeTime;
        AppealDetail detail;
    }

    struct AppealDetail {
        address finalAppealAddr;
        uint256 updateTime;
        string witnessReason;
        uint256 witnessAppealStatus;
        string observerReason;
        uint256 witnessHandleTime;
        uint256 observerHandleTime;
        address observerAddr;
        uint256 witnessHandleReward;
        uint256 observerHandleReward;
        uint256 witnessHandleCredit;
        uint256 observerHandleCredit;
        uint256 witReward;
        uint256 witSub;
        uint256 witCreditR;
        uint256 witCreditS;
    }

    mapping(uint256 => Appeal) public appeals;
    mapping(uint256 => uint256) public appealIndex;

    Appeal[] public appealList;

    constructor(
        address _r,
        address _o,
        address _u
    ) {
        _rSt = RecordInterface(_r);
        _oSt = OrderInterface(_o);
        _uSt = UserInterface(_u);
        recAddr = _r;
    }

    modifier onlyWit(uint256 _o) {
        Appeal memory _al = appeals[_o];
        require(_al.witness == msg.sender, "1");
        require(_al.buyer != msg.sender && _al.seller != msg.sender, "2");
        _;
    }

    modifier onlyOb(uint256 _o) {
        Appeal memory _al = appeals[_o];
        require(_al.detail.observerAddr == msg.sender, "1");
        require(_al.buyer != msg.sender && _al.seller != msg.sender, "2");
        _;
    }

    modifier onlyBOS(uint256 _o) {
        OrderStorage.Order memory _or = _oSt.searchOrder(_o);
        require(
            _or.orderDetail.sellerAddr == msg.sender ||
                _or.orderDetail.buyerAddr == msg.sender,
            "1"
        );
        _;
    }

    function _insert(uint256 _o, uint256 _count) internal {
        OrderStorage.Order memory _or = _oSt.searchOrder(_o);

        require(appeals[_o].appealNo == uint256(0), "4");

        AppealDetail memory _detail = AppealDetail({
            finalAppealAddr: address(0),
            updateTime: uint256(0),
            witnessReason: "",
            observerReason: "",
            witnessAppealStatus: 0,
            witnessHandleTime: uint256(0),
            observerHandleTime: uint256(0),
            observerAddr: address(0),
            witnessHandleReward: 0,
            observerHandleReward: 0,
            witnessHandleCredit: 0,
            observerHandleCredit: 0,
            witReward: 0,
            witSub: 0,
            witCreditR: 0,
            witCreditS: 0
        });

        uint256 _appealNo = block.timestamp;

        Appeal memory _appeal = Appeal({
            user: msg.sender,
            appealNo: _appealNo,
            orderNo: _o,
            witness: address(0),
            buyer: _or.orderDetail.buyerAddr,
            seller: _or.orderDetail.sellerAddr,
            mortgage: _count,
            status: 1,
            appealTime: block.timestamp,
            witTakeTime: 0,
            obTakeTime: 0,
            detail: _detail
        });

        appeals[_o] = _appeal;

        appealList.push(_appeal);
        appealIndex[_o] = appealList.length - 1;

        chanT(_or.orderDetail.sellerAddr, _or.orderDetail.buyerAddr, 1, 0);
    }

    function chanT(
        address _seller,
        address _buyer,
        uint256 _t,
        uint256 _r
    ) internal {
        uint256 _tc = _rSt.getTradeCredit();
        uint256 _rs = _rSt.getSubTCredit();

        UserStorage.User memory _user = _uSt.searchUser(_seller);
        UserStorage.TradeStats memory _tr = _user.tradeStats;

        uint256 _c = _user.credit;
        if (_t == 1) {
            _tr.tradeTotal = _tr.tradeTotal > 0 ? (_tr.tradeTotal - 1) : 0;

            _c = (_c >= _tc) ? (_c - _tc) : 0;
        } else if (_t == 2) {
            _tr.tradeTotal += 1;

            if (_r == 1) {
                _c += _tc;
            } else if (_r == 2) {
                _c = (_c >= _rs) ? (_c - _rs) : 0;
            }
        }

        _uSt.updateTradeStats(_seller, _tr, _c);

        UserStorage.User memory _user2 = _uSt.searchUser(_buyer);
        UserStorage.TradeStats memory _tr2 = _user2.tradeStats;
        uint256 _c2 = _user2.credit;
        if (_t == 1) {
            _tr2.tradeTotal = _tr2.tradeTotal > 0 ? (_tr2.tradeTotal - 1) : 0;

            _c2 = (_c2 >= _tc) ? (_c2 - _tc) : 0;
        } else if (_t == 2) {
            _tr2.tradeTotal += 1;

            if (_r == 1) {
                _c2 = (_c2 >= _rs) ? (_c2 - _rs) : 0;
            } else if (_r == 2) {
                _c2 += _tc;
            }
        }

        _uSt.updateTradeStats(_buyer, _tr2, _c2);
    }

    function applyAppeal(uint256 _o) external onlyBOS(_o) {
        uint256 _fee = _rSt.getAppealFee();
        _insert(_o, _fee);

        TokenTransfer _tokenTransfer = _rSt.setERC20Address("AIR");
        _tokenTransfer.transferFrom(msg.sender, recAddr, _fee);
    }

    function takeWit(uint256 _o) external {
        Appeal memory _al = appeals[_o];

        require(_al.buyer != msg.sender && _al.seller != msg.sender, "1");

        require(_al.witness == address(0), "2");
        require(_al.status == 1, "3");

        bool _f = witOrOb(1);
        require(_f, "4");

        _al.witness = msg.sender;
        _al.witTakeTime = block.timestamp;

        appeals[_o] = _al;
        appealList[appealIndex[_o]] = _al;
    }

    function takeOb(uint256 _o) external {
        Appeal memory _al = appeals[_o];

        require(_al.buyer != msg.sender && _al.seller != msg.sender, "1");

        require(_al.status == 4 || _al.status == 5, "2");
        require(_al.detail.observerAddr == address(0), "3");

        bool _f = witOrOb(2);
        require(_f, "4");

        _al.detail.observerAddr = msg.sender;
        _al.obTakeTime = block.timestamp;

        appeals[_o] = _al;
        appealList[appealIndex[_o]] = _al;
    }

    function changeHandler(uint256 _o, uint256 _type) external {
        Appeal memory _al = appeals[_o];

        if (_type == 1) {
            require(_al.status == 1, "2");
            require(_al.witness != address(0), "3");
            require(block.timestamp - _al.witTakeTime > 24 hours, "4");

            _al.witness = address(0);
            _al.witTakeTime = 0;
        } else if (_type == 2) {
            require(_al.status == 4 || _al.status == 5, "5");
            require(_al.detail.observerAddr != address(0), "6");
            require(block.timestamp - _al.obTakeTime > 24 hours, "7");

            _al.detail.observerAddr = address(0);
            _al.obTakeTime = 0;
        }

        appeals[_o] = _al;
        appealList[appealIndex[_o]] = _al;
    }

    function witOrOb(uint256 _f) internal view returns (bool) {
        UserStorage.User memory _user = _uSt.searchUser(msg.sender);
        if (_user.userFlag == _f) {
            return true;
        }
        return false;
    }

    function applyFinal(uint256 _o) external onlyBOS(_o) {
        Appeal memory _al = appeals[_o];

        require(_al.status == 2 || _al.status == 3, "1");

        require(
            block.timestamp - _al.detail.witnessHandleTime <= 24 hours,
            "2"
        );

        chanT(_al.seller, _al.buyer, 1, 0);

        uint256 _fee = _rSt.getAppealFeeFinal();

        TokenTransfer _tokenTransfer = _rSt.setERC20Address("AIR");
        _tokenTransfer.transferFrom(msg.sender, recAddr, _fee);

        if (_al.status == 2) {
            _al.status = 4;
        } else if (_al.status == 3) {
            _al.status = 5;
        }
        _al.detail.finalAppealAddr = msg.sender;
        _al.detail.updateTime = block.timestamp;
        appeals[_o] = _al;
        appealList[appealIndex[_o]] = _al;
    }

    function witnessOpt(
        uint256 _o,
        string memory _r,
        uint256 _s
    ) external onlyWit(_o) {
        require(_s == 2 || _s == 3, "1");
        Appeal memory _al = appeals[_o];

        require(_al.status == 1, "2");
        uint256 _fee = _rSt.getAppealFee();
        uint256 _rcedit = _rSt.getWitnessHandleCredit();

        _al.status = _s;
        _al.detail.witnessAppealStatus = _s;
        _al.detail.witnessReason = _r;
        _al.detail.witnessHandleTime = block.timestamp;
        _al.detail.witnessHandleReward = _fee;
        _al.detail.witnessHandleCredit = _rcedit;
        _al.detail.witReward = _fee;
        _al.detail.witCreditR = _rcedit;

        _al.detail.updateTime = block.timestamp;
        appeals[_o] = _al;
        appealList[appealIndex[_o]] = _al;

        if (_s == 2) {
            if (_al.user == _al.buyer) {
                _rSt.subAvaAppeal(_al.seller, _al.buyer, _al, _fee, 1, 0);
                chanT(_al.seller, _al.buyer, 2, 2);
            } else if (_al.user == _al.seller) {
                _rSt.subAvaAppeal(_al.buyer, _al.seller, _al, _fee, 1, 0);

                chanT(_al.seller, _al.buyer, 2, 1);
            }
        }

        if (_s == 3) {
            if (_al.user == _al.buyer) {
                _rSt.subAvaAppeal(_al.buyer, _al.seller, _al, _fee, 1, 1);
                chanT(_al.seller, _al.buyer, 2, 1);
            } else if (_al.user == _al.seller) {
                _rSt.subAvaAppeal(_al.seller, _al.buyer, _al, _fee, 1, 1);
                chanT(_al.seller, _al.buyer, 2, 2);
            }
        }
    }

    function observerOpt(
        uint256 _o,
        string memory _r,
        uint256 _s
    ) external onlyOb(_o) {
        require(_s == 6 || _s == 7, "1");
        Appeal memory _appeal = appeals[_o];

        require(_appeal.status == 4 || _appeal.status == 5, "2");
        uint256 _fee = _rSt.getAppealFeeFinal();
        uint256 _rcedit = _rSt.getObserverHandleCredit();

        _appeal.status = _s;
        _appeal.detail.observerReason = _r;
        _appeal.detail.observerHandleTime = block.timestamp;
        _appeal.detail.observerHandleReward = _fee;
        _appeal.detail.observerHandleCredit = _rcedit;

        uint256 _subWC = _rSt.getSubWitCredit();
        uint256 _subWF = _rSt.getSubWitFee();

        if (_s == 6) {
            if (_appeal.user == _appeal.buyer) {
                _rSt.subAvaAppeal(
                    _appeal.seller,
                    _appeal.buyer,
                    _appeal,
                    _fee,
                    2,
                    0
                );

                chanT(_appeal.seller, _appeal.buyer, 2, 1);
                _rSt.subFrozenTotal(_o, _appeal.buyer);
            } else if (_appeal.user == _appeal.seller) {
                _rSt.subAvaAppeal(
                    _appeal.buyer,
                    _appeal.seller,
                    _appeal,
                    _fee,
                    2,
                    0
                );

                chanT(_appeal.seller, _appeal.buyer, 2, 2);
                _rSt.subFrozenTotal(_o, _appeal.seller);
            }
            if (_appeal.detail.witnessAppealStatus == 3) {
                _appeal.detail.witSub = _subWF;
                _appeal.detail.witCreditS = _subWC;

                if (_appeal.detail.witnessHandleCredit >= _subWC) {
                    _appeal.detail.witnessHandleCredit = SafeMath.sub(
                        _appeal.detail.witnessHandleCredit,
                        _subWC
                    );
                } else {
                    _appeal.detail.witnessHandleCredit = 0;
                }
                _rSt.subWitnessAvailable(_appeal.witness);
            }
        }

        if (_s == 7) {
            if (_appeal.user == _appeal.buyer) {
                _rSt.subAvaAppeal(
                    _appeal.buyer,
                    _appeal.seller,
                    _appeal,
                    _fee,
                    2,
                    1
                );
                chanT(_appeal.seller, _appeal.buyer, 2, 1);
                _rSt.subFrozenTotal(_o, _appeal.seller);
            } else if (_appeal.user == _appeal.seller) {
                _rSt.subAvaAppeal(
                    _appeal.seller,
                    _appeal.buyer,
                    _appeal,
                    _fee,
                    2,
                    1
                );
                chanT(_appeal.seller, _appeal.buyer, 2, 2);
                _rSt.subFrozenTotal(_o, _appeal.buyer);
            }
            if (_appeal.detail.witnessAppealStatus == 2) {
                _appeal.detail.witSub = _subWF;
                _appeal.detail.witCreditS = _subWC;

                if (_appeal.detail.witnessHandleCredit >= _subWC) {
                    _appeal.detail.witnessHandleCredit = SafeMath.sub(
                        _appeal.detail.witnessHandleCredit,
                        _subWC
                    );
                } else {
                    _appeal.detail.witnessHandleCredit = 0;
                }
                _rSt.subWitnessAvailable(_appeal.witness);
            }
        }

        _appeal.detail.updateTime = block.timestamp;
        appeals[_o] = _appeal;
        appealList[appealIndex[_o]] = _appeal;
    }

    function searchAppeal(uint256 _o)
        external
        view
        returns (Appeal memory appeal)
    {
        return appeals[_o];
    }

    function searchAppealList() external view returns (Appeal[] memory) {
        return appealList;
    }
}

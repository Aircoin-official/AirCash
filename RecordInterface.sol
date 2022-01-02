// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;
import "./RestStorage.sol";
import './OrderStorage.sol';
import './UserStorage.sol';
import './RecordStorage.sol';
import './AppealStorage.sol';

interface RecordInterface {
    function getErcBalance(string memory _coinType, address _addr) external returns(uint);
    function getAvailableTotal(address _addr, string memory _coinType) external returns(uint);
    function getFrozenTotal(address _addr, string memory _coinType) external returns(uint);
    function addAvailableTotal(address _addr, string memory _coinType, uint remainHoldCoin) external;
    function subAvaAppeal(address _from, address _to, AppealStorage.Appeal memory _al, uint _amt, uint _type, uint _self) external;
    function subWitnessAvailable(address _addr) external;
    function setERC20Address(string memory _coinType) external returns(TokenTransfer);
    function subFrozenTotal(uint _orderNo, address _addr) external;
    function addRecord(address _addr, string memory _tradeHash, string memory _coinType, uint _hostCount, uint _hostStatus, uint _hostType, uint _hostDirection) external;
    function getAppealFee() external view returns(uint);
    function getAppealFeeFinal() external view returns(uint);
    function getWitnessHandleReward() external view returns(uint);
    function getObserverHandleReward() external view returns(uint);
    function getWitnessHandleCredit() external view returns(uint);
    function getObserverHandleCredit() external view returns(uint); 
    function getSubWitCredit() external view returns(uint);
    function getOpenTrade() external view returns(bool);
    function getTradeCredit() external view returns(uint);
    function getSubTCredit() external view returns(uint);
    function getSubWitFee() external view returns(uint);
}
interface RestInterface {
    function searchRest(uint _restNo) external returns(RestStorage.Rest memory rest);
    function getRestFrozenTotal(address _addr, uint _restNo) external returns(uint);
    function updateRestFinishCount(uint _restNo, uint _coinCount) external returns(uint);
    function addRestRemainCount(uint _restNo, uint _remainCount) external returns(uint);
}
interface OrderInterface {
    function searchOrder(uint _orderNo) external returns(OrderStorage.Order memory order);
}
interface UserInterface {
    function searchUser(address _addr) external view returns(UserStorage.User memory user);
    function searchWitnessList(uint _userFlag) external returns(UserStorage.User[] memory userList);
    function updateTradeStats(address _addr, UserStorage.TradeStats memory _tradeStats, uint _credit) external;
    function updateMorgageStats(address _addr, UserStorage.MorgageStats memory _morgageStats) external;
    function updateUserRole(address _addr, uint _userFlag) external;
}
interface AppealInterface {
    function searchAppeal(uint _o) external view returns(AppealStorage.Appeal memory appeal);
}

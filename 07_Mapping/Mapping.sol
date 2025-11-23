// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
contract Mapping {
    mapping(uint => address) public idToAddress; // id映射到地址
    mapping(address => address) public swapPair; // 币对的映射，地址到地址
    //声明映射的格式为mapping(_KeyType => _ValueType)
    // 规则1. _KeyType 不能是自定义的, 下面这个例子会报错
    // _KeyType 可以是 内置值类型，string, bytes, 合约，枚举类型
    // 我们定义一个结构体 Struct
    // struct Student{
    //    uint256 id;
    //    uint256 score; 
    //}
    // mapping(Struct => uint) public testVar;

//映射的存储位置必须是storage
    function writeMap (uint _Key, address _Value) public{
        idToAddress[_Key] = _Value;
    }
}

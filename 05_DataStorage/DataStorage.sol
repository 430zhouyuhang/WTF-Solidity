// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 状态变量是永久存储在智能合约的区块链存储中的数据。在合约内部、函数外部声明。它们在整个合约范围内都是可访问的。
contract DataStorage {
    // The data location of x is storage.
    // This is the only place where the
    // data location can be omitted.
    //对于状态变量，数据位置只能是 'storage'
    uint[] public x = [1,2,3];
    function fStorage() public{
        //声明一个storage的变量xStorage，指向x。修改xStorage也会影响x
        uint[] storage xStorage = x;
        xStorage[0] = 100;
    }

    
    function demonstrateMemoryReference() public pure returns (uint8, uint8, uint8) {
            // 1. 在 memory 中创建原始数组
            uint8[] memory originalArray = new uint8[](3);
            originalArray[0] = 10;
            originalArray[1] = 20;
            originalArray[2] = 30;    

            // 2. 将 memory 数组赋值给另一个 memory 变量
            // 这里不会复制数据，而是创建引用！
            uint8[] memory assignedArray = originalArray;            
            // 3. 通过新变量修改数据
            assignedArray[1] = 99; // 修改第二个元素
            
            // 4. 验证原数组是否也被修改
            // 如果原理成立，originalArray[1] 应该也变成了 99
            
            return (originalArray[0], originalArray[1], originalArray[2]);
            // 返回结果将是：(10, 99, 30)
            // 这证明两个变量指向同一块内存！
        }

    function fMemory() public view{
        //声明一个Memory的变量xMemory，复制storage数据位置的x。修改xMemory不会影响x
        uint[] memory xMemory = x;
        xMemory[0] = 100;
        xMemory[1] = 200;
        uint[] memory xMemory2 = x;
        xMemory2[0] = 300;
    }

    function fCalldata(uint[] calldata _x) public pure returns(uint[] calldata){
        //参数为calldata数组，不能被修改
        // _x[0] = 0 //这样修改会报错
        return(_x);
    }
}

contract Variables {
    uint public x = 1;
    uint public y;
    string public z;

    function foo() external{
        // 可以在函数里更改状态变量的值
        x = 5;
        y = 2;
        z = "0xAA";
    }

// 局部变量是仅在函数执行过程中有效的变量，函数退出后，变量无效。局部变量的数据存储在内存里，不上链，gas低。
    function bar() external pure returns(uint){
        uint xx = 1;
        uint yy = 3;
        uint zz = xx + yy;
        return(zz);
    }

// 全局变量是全局范围工作的变量，都是solidity预留关键字。
    function global() external view returns(address, uint, bytes memory){
        // 3个常用的全局变量：msg.sender，block.number和msg.data，他们分别代表请求发起地址，当前区块高度，和请求数据。
        address sender = msg.sender;
        uint blockNum = block.number;
        bytes memory data = msg.data;
        return(sender, blockNum, data);
    }
//Solidity中不存在小数点，以0代替为小数点，来确保交易的精确度，并且防止精度的损失，利用以太单位wei可以避免误算的问题，方便程序员在合约中处理货币交易。
    function weiUnit() external pure returns(uint) {
        assert(1 wei == 1e0);
        assert(1 wei == 1);
        return 1 wei;
    }

    function gweiUnit() external pure returns(uint) {
        assert(1 gwei == 1e9);
        assert(1 gwei == 1000000000);
        return 1 gwei;
    }

    function etherUnit() external pure returns(uint) {
        assert(1 ether == 1e18);
        assert(1 ether == 1000000000000000000);
        return 1 ether;
    }
    
    function secondsUnit() external pure returns(uint) {
        assert(1 seconds == 1);
        return 1 seconds;
    }

    function minutesUnit() external pure returns(uint) {
        assert(1 minutes == 60);
        assert(1 minutes == 60 seconds);
        return 1 minutes;
    }

    function hoursUnit() external pure returns(uint) {
        assert(1 hours == 3600);
        assert(1 hours == 60 minutes);
        return 1 hours;
    }

    function daysUnit() external pure returns(uint) {
        assert(1 days == 86400);
        assert(1 days == 24 hours);
        return 1 days;
    }

    function weeksUnit() external pure returns(uint) {
        assert(1 weeks == 604800);
        assert(1 weeks == 7 days);
        return 1 weeks;
    }
}




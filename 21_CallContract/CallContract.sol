// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract OtherContract {
    uint256 private _x = 0; // 状态变量x
    // 收到eth事件，记录amount和gas
    event Log(uint amount, uint gas);
    
    // 返回合约ETH余额
    function getBalance() view public returns(uint) {
        return address(this).balance;
    }

    // 可以调整状态变量_x的函数，并且可以往合约转ETH (payable)
    function setX(uint256 x) external payable{
        _x = x;
        // 如果转入ETH，则释放Log事件
        if(msg.value > 0){
            emit Log(msg.value, gasleft());
        }
    }

    // 读取x
    function getX() external view returns(uint x){
        x = _x;
    }
}

contract CallContract{
    // 传入合约地址,可以在函数里传入目标合约地址，生成目标合约的引用，然后调用目标函数。
    function callSetX(address _Address, uint256 x) external{
        OtherContract(_Address).setX(x);
    }

    // 直接在函数里传入合约的引用，只需要把上面参数的address类型改为目标合约名，比如OtherContract,该函数参数OtherContract _Address底层类型仍然是address
    function callGetX(OtherContract _Address) external view returns(uint x){
        x = _Address.getX();
    }

    // 法3 创建合约变量
    function callGetX2(address _Address) external view returns(uint x){
        OtherContract oc = OtherContract(_Address);
        x = oc.getX();
    }
    // 调用合约并发送ETH
    // 如果目标合约的函数是payable的，那么我们可以通过调用它来给合约转账：_Name(_Address).f{value: _Value}()，其中_Name是合约名，_Address是合约地址，f是目标函数名，_Value是要转的ETH数额（以wei为单位）。
    function setXTransferETH(address otherContract, uint256 x) payable external{
        OtherContract(otherContract).setX{value: msg.value}(x);
    }
}

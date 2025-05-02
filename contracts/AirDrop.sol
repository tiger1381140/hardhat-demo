// SPDX-License-Identifier: MIT
// By 0xAA
pragma solidity ^0.8.28;

import "./IERC20.sol";

/* @notice 向多个地址转账ERC20代币 */
contract Airdrop {
    mapping(address => uint) failTransferList;

    /* @notice 向多个地址转账ERC20代币，使用前需要先授权
     * @param _token 转账的ERC20代币地址
     * @param _addresses 空投地址数组
     * @param _amounts 代币数量数组（每个地址的空投数量）
    */
    function multiTransferToken(address _token, address[] calldata _addresses, uint256[] calldata _amounts) external {
        /* 检查：_addresses和_amounts数组的长度相等 */
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");

        /* 检查：授权代币数量 > 空投代币总量 */
        IERC20 token = IERC20(_token);
        uint _amountSum = getSum(_amounts);
        require(token.allowance(msg.sender, address(this)) > _amountSum, "Need Approve ERC20 token");

        /* for循环，利用transferFrom函数发送空投 */
        for (uint256 i; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }

    /* @notice 向多个地址转账ETH */
    function multiTransferETH(address payable[] calldata _addresses, uint256[] calldata _amounts) public payable {
        /* 检查：_addresses和_amounts数组的长度相等 */
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");

        /* 检查转入ETH等于空投总量 */
        uint _amountSum = getSum(_amounts);
        require(msg.value == _amountSum, "Transfer amount error");

        /* for循环，利用transfer函数发送ETH */
        for (uint256 i = 0; i < _addresses.length; i++) {
            /* 注释代码有Dos攻击风险, 并且transfer 也是不推荐写法
             * Dos攻击 具体参考 https://github.com/AmazingAng/WTF-Solidity/blob/main/S09_DoS/readme.md
             * _addresses[i].transfer(_amounts[i]);
             */
            (bool success, ) = _addresses[i].call{value: _amounts[i]}("");
            if (!success) {
                failTransferList[_addresses[i]] = _amounts[i];
            }
        }
    }

    /* @notice 给空投失败提供主动操作机会 */
    function withdrawFromFailList(address _to) public {
        uint failAmount = failTransferList[msg.sender];
        require(failAmount > 0, "You are not in failed list");
        failTransferList[msg.sender] = 0;
        (bool success, ) = _to.call{value: failAmount}("");
        require(success, "Fail withdraw");
    }

    /* @notice 数组求和函数 */
    function getSum(uint256[] calldata _arr) public pure returns (uint sum) {
        for (uint i = 0; i < _arr.length; i++) sum = sum + _arr[i];
    }
}
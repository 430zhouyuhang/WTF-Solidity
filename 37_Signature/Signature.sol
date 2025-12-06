// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../34_ERC721/ERC721.sol";

/**
 * @title ECDSA 库
 * @dev 提供链上签名验证的函数
 */
library ECDSA {
    /**
     * @dev 验证签名是否由指定签名者 signer 签署
     * @param _msgHash 消息哈希
     * @param _signature 签名
     * @param _signer 官方签名者地址
     * @return bool 签名是否有效
     */
    function verify(
        bytes32 _msgHash,
        bytes memory _signature,
        address _signer
    ) internal pure returns (bool) {
        return recoverSigner(_msgHash, _signature) == _signer;
    }

    /**
     * @dev 从签名中恢复签名者地址
     * @param _msgHash 消息哈希
     * @param _signature 签名
     * @return address 签名者地址
     */
    function recoverSigner(bytes32 _msgHash, bytes memory _signature) internal pure returns (address){
        // ECDSA标准签名长度是65字节(r=32,s=32,v=1)
        require(_signature.length == 65, "invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // 内联汇编提取 r, s, v
        assembly {
            // r: 签名的前32字节
            r := mload(add(_signature, 0x20))
            // s: 签名的中间32字节
            s := mload(add(_signature, 0x40))
            // v: 签名的最后1字节
            v := byte(0, mload(add(_signature, 0x60)))
        }

        // 使用ecrecover恢复签名者地址
        return ecrecover(_msgHash, v, r, s);
    }

    /**
     * @dev 获取以太坊标准签名消息hash
     * 添加 "\x19Ethereum Signed Message:\n32" 前缀，防止直接签名交易
     * @param hash 原始消息hash
     * @return bytes32 以太坊签名hash
     */
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

/**
 * @title SignatureNFT
 * @dev 使用ECDSA签名验证发放NFT
 */
contract SignatureNFT is ERC721 {
    // 官方签名地址（持有私钥离线签名）
    address immutable public signer;

    // 记录已mint的用户地址，防止重复mint
    mapping(address => bool) public mintedAddress;

    /**
     * @dev 构造函数
     * @param _name NFT合集名称
     * @param _symbol NFT合集代号
     * @param _signer 官方签名地址
     */
    constructor(string memory _name, string memory _symbol, address _signer)
        ERC721(_name, _symbol)
    {
        signer = _signer;
    }

    /**
     * @dev 利用ECDSA验证签名并执行mint
     * @param _account 用户地址
     * @param _tokenId mint的NFT tokenId
     * @param _signature 官方签名
     */
    function mint(address _account, uint256 _tokenId, bytes memory _signature) external {
        // 将_account和_tokenId生成消息hash
        bytes32 _msgHash = getMessageHash(_account, _tokenId);

        // 转换为以太坊签名hash
        bytes32 _ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_msgHash);

        // 验证签名是否由官方 signer 签署
        require(verify(_ethSignedMessageHash, _signature), "Invalid signature");

        // 检查是否已经mint过
        require(!mintedAddress[_account], "Already minted!");

        // 标记该地址已mint
        mintedAddress[_account] = true;

        // 执行mint
        _mint(_account, _tokenId);
    }

    /**
     * @dev 生成消息hash
     * @param _account 用户地址
     * @param _tokenId NFT tokenId
     * @return bytes32 消息hash
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns(bytes32) {
        // 将用户地址和tokenId打包后keccak256哈希
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

    /**
     * @dev 调用ECDSA库的verify方法验证签名
     * @param _msgHash 消息hash
     * @param _signature 签名
     * @return bool 是否验证通过
     */
    function verify(bytes32 _msgHash, bytes memory _signature) public view returns (bool) {
        return ECDSA.verify(_msgHash, _signature, signer);
    }
}

/**
 * @title VerifySignature
 * @dev 演示ECDSA签名验证流程
 */
contract VerifySignature {
    /**
     * @dev 生成消息hash
     */
    function getMessageHash(address _addr, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addr, _tokenId));
    }

    /**
     * @dev 获取以太坊签名消息hash
     */
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    /**
     * @dev 验证签名是否有效
     * @param _signer 官方签名者地址
     * @param _addr 用户地址
     * @param _tokenId NFT tokenId
     * @param signature 签名
     * @return bool 是否有效
     */
    function verify(
        address _signer,
        address _addr,
        uint _tokenId,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_addr, _tokenId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    /**
     * @dev 从签名中恢复签名者地址
     */
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev 拆解签名为 r, s, v
     */
    function splitSignature(bytes memory sig)
        public
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }
    }
}

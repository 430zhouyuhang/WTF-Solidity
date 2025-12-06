// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../34_ERC721/ERC721.sol";

// ECDSA库
library ECDSA{
    /**
     * @dev 通过ECDSA，验证签名地址是否正确，如果正确则返回true
     * _msgHash为消息的hash
     * _signature为签名
     * _signer为签名地址
     */
    function verify(bytes32 _msgHash, bytes memory _signature, address _signer) internal pure returns (bool) {
        return recoverSigner(_msgHash, _signature) == _signer;
    }

    // @dev 从_msgHash和签名_signature中恢复signer地址
    function recoverSigner(bytes32 _msgHash, bytes memory _signature) internal pure returns (address){
        // 检查签名长度，65是标准r,s,v签名的长度
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        // 目前只能用assembly (内联汇编)来从签名中获得r,s,v的值
        assembly {
            /*
            前32 bytes存储签名的长度 (动态数组存储规则)
            add(sig, 32) = sig的指针 + 32
            等效为略过signature的前32 bytes
            mload(p) 载入从内存地址p起始的接下来32 bytes数据
            */
            // 读取长度数据后的32 bytes
            r := mload(add(_signature, 0x20))
            // 读取之后的32 bytes
            s := mload(add(_signature, 0x40))
            // 读取最后一个byte
            v := byte(0, mload(add(_signature, 0x60)))
        }
        // 使用ecrecover(全局函数)：利用 msgHash 和 r,s,v 恢复 signer 地址
        return ecrecover(_msgHash, v, r, s);
    }
    
    /**
     * @dev 返回 以太坊签名消息
     * `hash`：消息哈希 
     * 遵从以太坊签名标准：https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * 以及`EIP191`:https://eips.ethereum.org/EIPS/eip-191`
     * 添加"\x19Ethereum Signed Message:\n32"字段，防止签名的是可执行交易。
     */
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

/**
 * @title SignatureNFT
 * @dev 使用 ECDSA 签名发放白名单的 ERC721 NFT 合约示例
 */
contract SignatureNFT is ERC721 {
    // 官方签名者地址（用于验证用户签名是否合法）
    address immutable public signer;

    // 记录已经 mint 的用户地址，防止重复 mint
    mapping(address => bool) public mintedAddress;

    /**
     * @dev 构造函数，初始化 NFT 名称、代号，以及官方签名者地址
     * @param _name NFT 名称
     * @param _symbol NFT 代号
     * @param _signer 官方签名者地址（后端私钥对应的公钥地址）
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _signer
    ) ERC721(_name, _symbol) {
        signer = _signer;
    }

    /**
     * @dev mint NFT
     * 用户必须提供官方签名才能 mint，且同一地址只能 mint 一次
     * @param _account 用户地址
     * @param _tokenId NFT tokenId
     * @param _signature 官方签名（离线生成）
     */
    function mint(
        address _account,
        uint256 _tokenId,
        bytes memory _signature
    ) external {
        // 1. 生成消息 hash：将地址和 tokenId 打包
        bytes32 _msgHash = getMessageHash(_account, _tokenId);

        // 2. 生成以太坊签名消息 hash
        bytes32 _ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_msgHash);

        // 3. 验证 signature 是否由官方 signer 签发
        require(verify(_ethSignedMessageHash, _signature), "Invalid signature");

        // 4. 检查地址是否已经 mint
        require(!mintedAddress[_account], "Already minted!");

        // 5. 标记该地址已 mint
        mintedAddress[_account] = true;

        // 6. 执行 mint
        _mint(_account, _tokenId);
    }

    /**
     * @dev 生成消息 hash
     * @param _account 用户地址
     * @param _tokenId NFT tokenId
     * @return bytes32 消息 hash
     */
    function getMessageHash(address _account, uint256 _tokenId) public pure returns (bytes32) {
        // abi.encodePacked 将地址和 tokenId 紧凑编码成字节序列，然后 keccak256 哈希
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

    /**
     * @dev 使用 ECDSA 验证签名
     * @param _msgHash 已经生成的消息 hash
     * @param _signature 官方签名
     * @return bool 是否验证成功
     */
    function verify(bytes32 _msgHash, bytes memory _signature) public view returns (bool) {
        // 调用 OpenZeppelin 的 ECDSA 库，recover 出签名者地址
        return ECDSA.recover(_msgHash, _signature) == signer;
    }
}

/**
 * @title VerifySignature
 * @dev ECDSA 签名验证示例（包括签名拆解 r, s, v 的方法）
 * 用于演示链下签名、链上验证过程
 */
contract VerifySignature {
    /**
     * @dev 生成消息 hash（用户地址 + tokenId）
     */
    function getMessageHash(address _addr, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_addr, _tokenId));
    }

    /**
     * @dev 生成以太坊标准签名消息 hash
     * 说明：在以太坊客户端签名时，客户端会对原始消息加上前缀：
     * "\x19Ethereum Signed Message\n32" + message
     * 然后再签名
     */
    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
    }

    /**
     * @dev 验证签名是否有效
     * @param _signer 官方签名者地址
     * @param _addr 用户地址
     * @param _tokenId NFT tokenId
     * @param signature 用户提供的签名
     * @return bool 是否有效
     */
    function verify(
        address _signer,
        address _addr,
        uint256 _tokenId,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_addr, _tokenId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    /**
     * @dev 从签名中恢复签名者地址
     * @param _ethSignedMessageHash 消息 hash
     * @param _signature 签名
     */
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev 拆分签名为 r, s, v 三个部分
     * @param sig 签名，65 字节
     */
    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        // 检查签名长度
        require(sig.length == 65, "invalid signature length");

        assembly {
            // 前 32 字节是长度信息，跳过
            r := mload(add(sig, 0x20))  // r 部分（32字节）
            s := mload(add(sig, 0x40))  // s 部分（32字节）
            v := byte(0, mload(add(sig, 0x60))) // v 部分（1字节）
        }
    }
}


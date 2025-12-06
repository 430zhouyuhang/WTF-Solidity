
# ✅ ERC721 合约中 metadata 要写哪些？

**只需写 2 个部分即可：**

### **① 存一个 baseURI（元数据根路径）**

这是 metadata 的目录，比如：

```
https://my-nft.com/metadata/
```

### **② 重写`_baseURI()` ~~或直接覆盖 `tokenURI()`**~~

这是最关键的部分，让 ERC721 知道 metadata URL 的拼接方式。

---

# 🚀 最标准、最常用的 Metadata 实现（OpenZeppelin 风格）

👇下面给你完整可用模板，你以后写 ERC721 都可以直接用。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721, Ownable {
    string private _baseTokenURI;

    constructor(string memory baseURI) ERC721("MyNFT", "MNFT") Ownable(msg.sender) {
        _baseTokenURI = baseURI;
    }

    // ========================
    // 1. 设置 BaseURI（项目方可修改）
    // ========================
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // ========================
    // 2. 返回 BaseURI（供 ERC721 tokenURI 使用）
    // ========================
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // mint 示例
    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }
}
```

---

# ✅ ERC721 是如何生成最终的 tokenURI 的？

OpenZeppelin 的 ERC721 内置了 tokenURI 的实现：

```solidity
return string(abi.encodePacked(_baseURI(), tokenId.toString()));
```

所以最终：

```
_baseURI() = https://my-nft.com/metadata/
tokenId = 123

tokenURI(123) = "https://my-nft.com/metadata/123"
```

钱包（MetaMask、OpenSea）就会访问这个 URL 来获得 metadata JSON 文件。

---

# 🧩 metadata JSON 示例（你必须准备这个文件）

例如：

```
https://my-nft.com/metadata/123
```

文件内容如下（最标准格式）：

```json
{
  "name": "My NFT #123",
  "description": "This is an example NFT",
  "image": "https://my-nft.com/images/123.png",
  "attributes": [
    { "trait_type": "Rarity", "value": "Legendary" },
    { "trait_type": "Power", "value": 9001 }
  ]
}
```

注意：  
✔ 这些 JSON 文件不在链上，而是放在

- IPFS
    
- Arweave
    
- AWS / OSS / GitHub Pages
    
- 任何 HTTP 服务器
    

---

# 🎯 自定义 tokenURI（完全手写）示例

如果你想更灵活，也可以 **覆盖整个 `tokenURI`**：

```solidity
function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
{
    require(_exists(tokenId), "URI query for nonexistent token");

    return string(
        abi.encodePacked(_baseTokenURI, "/", tokenId.toString(), ".json")
    );
}
```

好处：

- 你可以加 `.json` 后缀
    
- 你可以根据不同 tokenId 返回不同路径
    
- 可支持多种 metadata 模式
    

---

# 🚨 关键点（非常重要）

在 ERC721 合约中，你**永远不存储 metadata 内容**：

❌ 不存 JSON  
❌ 不存图片

你只存一个东西：

### **metadata 的访问入口（URI 或 baseURI）**

钱包/市场会根据 tokenURI 去链下拉取文件。

---

# 📌 总结（你可以复制到笔记）

### **ERC721 合约中 metadata 部分必须实现：**

1. **baseURI 存储变量**
    
    - 存 metadata 所在目录
        
2. **覆盖 `_baseURI()` 或 `tokenURI()`**
    
    - 告诉 ERC721 如何拼接 metadata URL
        
3. **（可选）setter 函数**
    
    - 让 owner 可以修改 baseURI
        
4. **准备链下 metadata JSON**
    
    - 提供 NFT 的 name / image / attributes 等展示内容
        

---

如果你愿意，我还能给你：

✅ **完全去中心化的 metadata + 图片（IPFS 版本）模板**  
或  
✅ **支持 ERC721A 的 metadata 实现**

告诉我你想哪种？****
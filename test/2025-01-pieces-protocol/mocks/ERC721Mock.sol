// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721Mock is ERC721, Ownable {
    uint256 private _tokenIdCounter;

    constructor() ERC721("MockToken", "MTK") Ownable(msg.sender) {}

    function mint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter);
        _tokenIdCounter++;
    }
}

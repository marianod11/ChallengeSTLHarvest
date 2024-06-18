// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract STL is ERC20, Ownable {
    constructor(
        address initialOwner
    ) ERC20("STL", "STL") Ownable(initialOwner) {
        mint(initialOwner, 1000000000 ether);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

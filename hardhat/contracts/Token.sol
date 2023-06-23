// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract token is ERC20{
    //Initialize contract with 1million Tokens
    constructor() ERC20("Token", "TKN"){
        _mint (msg.sender,1000000 * 10 ** decimals());
    }

}



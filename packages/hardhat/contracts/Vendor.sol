pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {

    YourToken public yourToken;
    uint256 public constant tokensPerEth = 100;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);
    
    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    // ToDo: create a payable buyTokens() function:
    function buyTokens() public payable {
        require(yourToken.balanceOf(address(this)) >= (msg.value * tokensPerEth),
            "ERC20: transfer amount exceeds balance"
        );
        uint256 amount = msg.value * tokensPerEth;
        yourToken.transfer(msg.sender, amount);
        emit BuyTokens(msg.sender, msg.value, amount);
    }

    // ToDo: create a withdraw() function that lets the owner withdraw ETH
    function withdraw() public payable onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Ether withdraw not successful!");
    }

    // ToDo: create a sellTokens() function:
    function sellTokens(uint256 amount) public payable {
        yourToken.approve(address(this), amount);
        yourToken.transferFrom(msg.sender, address(this), amount);
        uint256 ethAmount = amount / tokensPerEth;
        (bool sent, ) = msg.sender.call{value: ethAmount}("");
        require(sent, "Ether not sent");
        emit SellTokens(msg.sender, amount, ethAmount);
    }
}
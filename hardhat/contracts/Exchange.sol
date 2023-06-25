// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public tokenAddress;

    // EXchange will inherit ERC20
    // Miniting and issuing  LP tokens

    constructor(address token) ERC20("ETH TOKEN LP token", "lpETHTOKEN") {
        require(token != address(0), "Token address passeed is null address");
        tokenAddress = token;
    }

    // Get balance of  'Token held by contract using getreserve

    function getReserve() public view returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    //Add Liquidty function

    function addLiquidty(
        uint256 amountOfToken
    ) public payable returns (uint256) {
        uint256 lpTokensToMint;
        uint256 ethReserveBalance = address(this).balance;
        uint256 tokenReserveBalance = getReserve();

        ERC20 token = ERC20(tokenAddress);

        if (tokenReserveBalance == 0) {
            //Transfer tokens From the User to the exchange
            token.transferFrom(msg.sender, address(this), amountOfToken);

            lpTokensToMint = ethReserveBalance;

            //mint lp to the user
            _mint(msg.sender, lpTokensToMint);
            return lpTokensToMint;
        }

        // If the reserve is not empty, calculate the amount of LP Tokens to be minted
        uint256 ethReservePriorToFunctionCall = ethReserveBalance - msg.value;
        uint256 minTokenAmountRequired = (msg.value * tokenReserveBalance) /
            ethReservePriorToFunctionCall;

        require(
            amountOfToken >= minTokenAmountRequired,
            "Insufficient amount of tokens provided"
        );
        //transfer token from the user to the exchange

        token.transferFrom(msg.sender, address(this), minTokenAmountRequired);

        lpTokensToMint =
            (totalSupply() * msg.value) /
            ethReservePriorToFunctionCall;

        _mint(msg.sender, lpTokensToMint);
        return lpTokensToMint;
    }

    //Remove Liquidity
    function removeLiquidty(
        uint256 amountOfLPTokens
    ) public returns (uint256, uint256) {
        //check amount of lp to be removed > 0 lp tokens
        require(
            amountOfLPTokens > 0,
            "Amount of Lp tokens to be removed  must be greater than 0"
        );
        uint256 ethReserveBalance = address(this).balance;
        uint256 lpTokenTotalSupply = totalSupply();

        // Calculate the amount of ETH and tokens to return to the user
        uint256 ethToReturn = (ethReserveBalance * amountOfLPTokens) /
            lpTokenTotalSupply;
        uint256 tokenToReturn = (getReserve() * amountOfLPTokens) /
            lpTokenTotalSupply;

        // burn lp and transfer tokens to the user
        _burn(msg.sender, amountOfLPTokens);
        payable(msg.sender).transfer(ethToReturn);
        ERC20(tokenAddress).transfer(msg.sender, tokenToReturn);
        return (ethToReturn, tokenToReturn);
    }

    //calculate amount to be received bassed on xy= (x+dx)- (y-dy)

  function getOutputAmountFromSwap(
    uint256 inputAmount,
    uint256 inputReserve,
    uint256 outputReserve
    ) public pure returns (uint256) {

    require(
        inputReserve > 0 && outputReserve > 0,
        "Reserves must be greater than 0" );

    uint256 inputAmountWithFee = inputAmount * 99;

    uint256 numerator = inputAmountWithFee * outputReserve;
    uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

    return numerator / denominator;
}


//allow user to swap ETH for tokens
function ethToTokenSwap(uint256 minTokensToReceive) public payable {
    uint256 tokenReserveBalance = getReserve();
    uint256 tokensToReceive = getOutputAmountFromSwap(
        msg.value,
        address(this).balance - msg.value,
        tokenReserveBalance
    );

    require(
        tokensToReceive >= minTokensToReceive,
        "Tokens received are less than minimum tokens expected"
    );

    ERC20(tokenAddress).transfer(msg.sender, tokensToReceive);
}

// tokenToEthSwap allows users to swap tokens for ETH
function tokenToEthSwap(
    uint256 tokensToSwap,
    uint256 minEthToReceive
) public {
    uint256 tokenReserveBalance = getReserve();
    uint256 ethToReceive = getOutputAmountFromSwap(
        tokensToSwap,
        tokenReserveBalance,
        address(this).balance
    );

    require(
        ethToReceive >= minEthToReceive,
        "ETH received is less than minimum ETH expected"
    );

    ERC20(tokenAddress).transferFrom(
        msg.sender,
        address(this),
        tokensToSwap
    );

    payable(msg.sender).transfer(ethToReceive);
}
}

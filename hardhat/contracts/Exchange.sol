// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// AMM-type contract to exchange between ETH & LPT (ficional token) (like Uniswap v1)
contract Exchange is ERC20 {
    address public tokenAddress;

    // Exchange inherits ERC20, because it's responsible for minting and issuing LP Tokens
    constructor(address token) ERC20("LP Token", "LPT") {
        require(token != address(0), "Token address passed is a null address");
        tokenAddress = token;
    }

    function getReserve() public view returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    function addLiquidity(
        uint256 amountOfToken
    ) public payable returns (uint256) {
        uint256 lpTokensToMint;
        uint256 ethReserveBalance = address(this).balance;
        uint256 tokenReserveBalance = getReserve();

        ERC20 token = ERC20(tokenAddress);

        // If the reserve is empty, take any user supplied value for initial liquidity
        if (tokenReserveBalance == 0) {
            token.transferFrom(msg.sender, address(this), amountOfToken);
            lpTokensToMint = ethReserveBalance;
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

        // Transfer the token from the user to the exchange
        token.transferFrom(msg.sender, address(this), minTokenAmountRequired);

        // Calculate the amount of LP tokens to be minted
        lpTokensToMint =
            (totalSupply() * msg.value) /
            ethReservePriorToFunctionCall;

        // Mint LP tokens to the user
        _mint(msg.sender, lpTokensToMint);

        return lpTokensToMint;
    }
}

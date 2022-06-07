//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error TransferFailed();

contract Token is ERC20, Ownable {

    /* Token Variables */
    address private marketingWallet;
    address private lpWallet;
    address private lpPair;
    address private devWallet;

    /* Tax Variables */
    uint8[] sellTaxValues = [10,15,20,25,30,35,40,45,50];
    uint8 buyTax = 6;
    uint8 devTax;
    uint8 marketingTax;
    uint8 liquidityTax;
    uint16 sellCount;
    uint16 buyCount;
    uint16 private maxSell;
    uint16 private maxBuy;

    constructor(
        string memory name, 
        string memory symbol,
        address _marketing,
        address _lpWallet,
        address _devWallet,
        uint8 _devTax,
        uint8 _marketingTax,
        uint8 _liquidityTax,
        uint16 _maxSell,
        uint16 _maxBuy
    ) ERC20(name, symbol){
        marketingWallet = _marketing;
        lpWallet = _lpWallet;
        devWallet = _devWallet;
        devTax = _devTax;
        marketingTax = _marketingTax;
        liquidityTax = _liquidityTax;
        maxSell = _maxSell;
        maxBuy = _maxBuy;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override virtual {
        uint256 taxAmount = takeTaxes(from, to, amount);
        uint256 amountReceived = amount - taxAmount;

        require(distributeTax(from, taxAmount));
        super._transfer(from, to, amountReceived);
        emit Transfer(from, to, amount); 
    }

    function mint(
        address to,
        uint256 amount
    ) external onlyOwner {
        _mint(to, amount);
    }

    function distributeTax(address from, uint256 taxAmount) internal returns (bool) {
        uint256 toMarketing = (taxAmount/100)*marketingTax;
        uint256 toDev = (taxAmount/100)*devTax;
        uint256 toLp = taxAmount - toMarketing - toDev;

        super._transfer(from, marketingWallet, toMarketing);
        super._transfer(from, devWallet, toDev);
        super._transfer(from, lpWallet, toLp);

        return true;
    }

    /* Tax Functions */

    function takeTaxes(
        address from, 
        address to, 
        uint256 amount
    ) internal returns (uint256) {
        uint256 currentFee;
        uint256 finalAmount;
        if (from == lpPair /* address(this)*/) { // buying 
            require(buyCount + 1 <=  maxBuy, "Transfer Failed");
            currentFee = buyTax;
            finalAmount = (amount/100)*currentFee;
            buyCount++;
        } else if (to == lpPair /* address(this)*/) { //selling
            require(sellCount + 1 <= maxSell, "Transfer Failed");
            uint256 tokenBalance = balanceOf(from);
            uint256 percentage = (amount/tokenBalance)*100;
            currentFee = getTax(percentage);
            finalAmount = (amount/100)*currentFee;
            sellCount++;
        } else {
            return amount; 
        }
        return finalAmount;
    }

    /* Parameter Functions */

    // 0 - DevWallet 1 - MarketingWallet 2 - LiquidityWallet
    function setWallets(address[3] calldata wallets) external onlyOwner{
        devWallet = wallets[0];
        marketingWallet = wallets[1];
        lpWallet = wallets[2];
    }

    // 0 - BuyTax 1 - DevTax 2 - MarketingTax 3 - LP Tax
    function setTaxes(uint8[4] calldata taxes) external onlyOwner{
        buyTax = taxes[0];
        devTax = taxes[1];
        marketingTax = taxes[2];
        liquidityTax = taxes[3];
    }

    function setMaxBuy(uint16 _maxBuy) external onlyOwner {
        maxBuy = _maxBuy;
    }

    function setMaxSell(uint16 _maxSell) external onlyOwner {
        maxSell = _maxSell;
    }

    function resetSellCount() external onlyOwner {
        sellCount =0;
    }

    function resetBuyCount() external onlyOwner {
        buyCount =0;
    }

    function setLpPair(address _lpPair) external onlyOwner {
        lpPair = _lpPair;
    }

    /* View / Pure Functions */

    function getTax(uint256 percentage) internal view returns (uint256) {
        if (percentage < 20){
            return sellTaxValues[0];
        } else if (percentage >= 20 && percentage < 30){
            return sellTaxValues[1];
        } else if (percentage >= 30 && percentage < 40){
            return sellTaxValues[2];
        } else if (percentage >= 40 && percentage < 50){
            return sellTaxValues[3];
        } else if (percentage >= 50 && percentage < 60){
            return sellTaxValues[4];
        } else if (percentage >= 60 && percentage < 70){
            return sellTaxValues[5];
        } else if (percentage >= 70 && percentage < 80){
            return sellTaxValues[6];
        } else if (percentage >= 80 && percentage < 90){
            return sellTaxValues[7];
        } else  {
            return sellTaxValues[8];
        }   
    }

}

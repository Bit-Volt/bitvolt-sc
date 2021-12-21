// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleToken  is ERC20 {

 constructor(string memory , string memory , uint256 ) {
     

        // _rOwned[_msgSender()] = _tTotal;

        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        // uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        //     .createPair(address(this), _uniswapV2Router.WETH());

        // uniswapV2Router = _uniswapV2Router;

        // _isExcludedFromFee[owner()] = true;
        // _isExcludedFromFee[address(this)] = true;
        // _isExcludedFromFee[marketingAddress] = true;
        // _isExcludedFromFee[projectAddress] = true;
        // _isExcludedFromFee[protectionAddress] = true;
        // _isExcludedFromFee[airdropAddressPrivate] = true;
        // _isExcludedFromFee[airdropAddressPublic] = true;


        // emit Transfer(address(0), _msgSender(), _tTotal);


    }



    
}
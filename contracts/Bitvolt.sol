// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";


contract SimpleToken is Context, IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _taxFee;
    uint256 private _liquidityFee;
    uint256 private _marketingFee;
    uint256 private _innovationFee;
    
    address payable public _marketingAddress;
    address payable public _innovatoinAddress;
    address payable public _LPAddress;


    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    
    uint256 private _tTotal;



 constructor(
    string memory name_,
    string memory symbol_,
    uint256 decimals_,
    uint tokenSupply_,
    uint taxfee_,
    uint liquidityFee_, 
    uint marketingFee_,
    uint innovationFee_, 
    address marketingAddress_,
    address innovationAddress_,
    address uniswapV2Pair_
     ) {

     _name = name_;
     _symbol = symbol_;
     _decimals = decimals_;
     _taxFee = taxfee_;
     _liquidityFee = liquidityFee_;
     _marketingFee = marketingFee_;
     _innovationFee = innovationFee_;

    _marketingAddress =  payable(marketingAddress_);
    
    _innovatoinAddress = payable(innovationAddress_);

  
     uniswapV2Router = IUniswapV2Router02(uniswapV2Pair);


     _tTotal = tokenSupply_ * (10** decimals_);
     

         emit Transfer(address(0), _msgSender(), _tTotal);
     
    }

function initContract() external onlyOwner {
       uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
         _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
}

    function name() public pure returns (string memory) {
        return _name;
    }

  
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

 
    function decimals() public pure returns (uint8) {
        return _decimals;
    }


    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

        function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
        function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

        function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }
    

}
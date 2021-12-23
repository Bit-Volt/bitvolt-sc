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

contract BITVOLT is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address private DEAD = 0x000000000000000000000000000000000000dEaD;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _taxFee;
    uint256 private _liquidityFee;
    uint256 private _marketingFee;
    uint256 private _innovationFee;

    address payable public liquidityAddress;
    address payable public marketingAddress;
    address payable public innovationAddress;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 private _tTotal;

    bool public tradingOpen = false;
    bool public sellPaused = false;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 tokenSupply_,
        uint256 liquidityFee_,
        uint256 marketingFee_,
        uint256 innovationFee_,
        address lpAddress_,
        address marketingAddress_,
        address innovationAddress_,
        address uniswapV2Router_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        _liquidityFee = liquidityFee_;
        _marketingFee = marketingFee_;
        _innovationFee = innovationFee_;

        liquidityAddress = payable(lpAddress_);
        marketingAddress = payable(marketingAddress_);
        innovationAddress = payable(innovationAddress_);

        uniswapV2Router = IUniswapV2Router02(uniswapV2Router_);

        _tTotal = tokenSupply_ * (10**decimals_);
        _tOwned[_msgSender()] = _tTotal;
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

    function openTrading() external onlyOwner {
        tradingOpen = true;
    }

    function toggleSell() external onlyOwner {
        sellPaused = !sellPaused;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
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
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (canBuy(from, to) || canSell(from, to)) {
            _tokenTransferWithTax(from, to, amount);
        } else {
            _transferStandard(from, to, amount);
        }
    }

    function canBuy(address sender, address recipient)
        private
        view
        returns (bool)
    {
        return tradingOpen && sender == uniswapV2Pair && recipient != DEAD;
    }

    function canSell(address sender, address recipient)
        private
        view
        returns (bool)
    {
        return
            tradingOpen &&
            !sellPaused &&
            sender != DEAD &&
            recipient == uniswapV2Pair;
    }

    function _tokenTransferWithTax(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 liquidityTax,
            uint256 marketingTax,
            uint256 innovationTax
        ) = calculateTax(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);

        _tOwned[liquidityAddress].add(liquidityTax);
        _tOwned[marketingAddress].add(marketingTax);
        _tOwned[innovationAddress].add(innovationTax);

        _tOwned[recipient] = _tOwned[recipient]
            .add(tAmount)
            .sub(liquidityTax)
            .sub(marketingTax)
            .sub(innovationTax);

        emit Transfer(sender, liquidityAddress, liquidityTax);
        emit Transfer(sender, marketingAddress, marketingTax);
        emit Transfer(sender, innovationAddress, innovationTax);
        emit Transfer(sender, recipient, _tOwned[recipient]);
    }

    function calculateTax(uint256 _amount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _amount.mul(_liquidityFee).div(10**2),
            _amount.mul(_marketingFee).div(10**2),
            _amount.mul(_innovationFee).div(10**2)
        );
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    //to recieve ETH from uniswapV2Router when swaping
    //TODO [LH]: Why is the empty
    receive() external payable {}
}

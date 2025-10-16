// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "./IERC20.sol";

// Constant sum AMM X + Y = K
contract CSAMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function _update(uint256 _reserve0, uint256 _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function swap(
        address _tokenIn,
        uint256 _amountIn
    ) external returns (uint256 amountOut) {
        require(_amountIn > 0, "amount in = 0");

        (
            IERC20 tokenIn,
            uint256 reserveIn,
            IERC20 tokenOut,
            uint256 reserveOut
        ) = (_tokenIn == address(token0))
                ? (token0, reserve0, token1, reserve1)
                : (token1, reserve1, token0, reserve0);

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);

        uint256 amountIn = tokenIn.balanceOf(address(this)) - reserveIn;
        amountOut = (amountIn * 997) / 1000;

        (uint256 reserve0_, uint256 reserve1_) = _tokenIn == address(token0)
            ? (reserveIn + amountIn, reserveOut - amountOut)
            : (reserveOut - amountOut, reserveIn + amountIn);

        tokenOut.transferFrom(address(this), msg.sender, amountOut);

        _update(reserve0_, reserve1_);
    }

    function _mint(address _to, uint256 _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function addLiquidity(
        uint256 _amount0,
        uint256 _amount1
    ) external returns (uint256 shares) {
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));

        uint256 d0 = bal0 - reserve0;
        uint256 d1 = bal1 - reserve1;

        if (totalSupply == 0) {
            shares = ((d0 + d1) * totalSupply) / (reserve0 + reserve1);
        } else {
            shares = d0 + d1;
        }
        require(shares > 0, "shares = 0");
        _mint(msg.sender, shares);

        _update(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
    }

    function _burn(address _from, uint256 _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    function removeLiquidity(
        uint256 _shares
    ) external returns (uint256 amount0, uint256 amount1) {
        // a = L * s / T
        amount0 = (reserve0 * _shares) / totalSupply;
        amount1 = (reserve1 * _shares) / totalSupply;

        _burn(msg.sender, _shares);
        _update(reserve0 - amount0, reserve1 - amount1);

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
    }
}

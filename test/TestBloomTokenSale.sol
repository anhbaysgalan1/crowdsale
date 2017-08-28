pragma solidity ^0.4.10;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "minimetoken/contracts/MiniMeToken.sol";
import "../contracts/Bloom.sol";
import "../contracts/BloomTokenSale.sol";
import "zeppelin-solidity/contracts/token/ERC20.sol";
import "./helpers/ThrowProxy.sol";

contract TestBloomTokenSale {
  uint256 public initialBalance = 1 ether;

  ThrowProxy throwProxy;

  function beforeEach() {
    throwProxy = new ThrowProxy(address(this));
  }

  function testTotalSupplyUsingDeployedContract() {
    Bloom bloom = new Bloom(new MiniMeTokenFactory());
    BloomTokenSale sale = new BloomTokenSale();
    bloom.changeController(address(sale));
    sale.setToken(address(bloom));

    uint256 totalBefore = sale.token().totalSupply();
    sale.allocateSupply();
    uint256 totalAfter = sale.token().totalSupply();

    Assert.equal(
      totalBefore,
      0,
      "The total supply should start at zero tokens."
    );

    Assert.equal(
      totalAfter,
      15e10,
      "The supply should be 15M after calling allocateSupply()"
    );

    Assert.equal(
      sale.token().balanceOf(address(0)),
      0,
      "Non-owner addresses should have a balance of zero"
    );

    Assert.equal(
      sale.token().balanceOf(address(sale)),
      15e10,
      "Token controller should be allocated the initial tokens"
    );
  }

  function testOwnerOnlySetToken() {
    TestBloomTokenSale(throwProxy).throwsWhenNonOwnerSetsToken();

    throwProxy.assertThrows("Should throw when non-owner tries to setToken");
  }

  function throwsWhenNonOwnerSetsToken() {
    BloomTokenSale sale = BloomTokenSale(DeployedAddresses.BloomTokenSale());

    sale.setToken(address(this));
  }

  function testOwnerOnlyAllocateSupply() {
    TestBloomTokenSale(throwProxy).throwsWhenNonOwnerAllocatesSupply();

    throwProxy.assertThrows("Should throw when non-owner tries to allocateSupply");
  }

  function throwsWhenNonOwnerAllocatesSupply() {
    BloomTokenSale sale = BloomTokenSale(DeployedAddresses.BloomTokenSale());

    sale.allocateSupply();
  }

  function testPurchase() {
    Bloom bloom = new Bloom(new MiniMeTokenFactory());
    BloomTokenSale sale = new BloomTokenSale();
    bloom.changeController(address(sale));
    sale.setToken(address(bloom));

    assert(sale.call.value(10000 wei)());

    Assert.equal(
      sale.token().balanceOf(address(this)),
      10,
      "Expected 10,000 wei to buy me 10 tokens"
    );

    Assert.equal(
      sale.balance,
      10000 wei,
      "Expected a 10k balance in the sale"
    );
  }
}
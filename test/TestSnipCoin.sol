pragma solidity ^0.4.15;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SnipCoin.sol";

contract TestSnipCoin {

  function testHelloWorld() {
    uint actual = 0;
    uint expected = 0;
    Assert.equal(actual,expected, "Zero should be zero");
  }
}

var SnipCoin = artifacts.require("./SnipCoin.sol");

module.exports = function(deployer) {
  deployer.deploy(SnipCoin);
};

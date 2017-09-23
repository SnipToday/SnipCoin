var SnipCoin = artifacts.require("./SnipCoin.sol");
var WEI_IN_ETHER = 1000 * 1000 * 1000 * 1000 * 1000 * 1000; // Number of wei in 1 eth

contract('SnipCoin', function(accounts) {
	var crowdsale;

	it ("hello world SnipCoin", function()
	{
		assert.equal(0,0);
	});

	it("initialize contract", function()
	{
      return SnipCoin.new().then(function(_crowdsale) {
      crowdsale = _crowdsale
    });
  	});

	it ("Check initial supply", function()
	{
		return crowdsale.totalSupply().then(function(totalSupply) {
      	assert.equal(totalSupply.valueOf(), 10000000000 * 1000000000000000000, "didn't get right amount of initial supply");
	});
	});
	it ("Check initial balance", function()
	{
      	return crowdsale.getBalance.call(accounts[0]).then(function(balance) {
      	assert.equal(balance.valueOf(), 10000000000 * 1000000000000000000, "didn't get right initial balance");
	});
	});
	it ("Check symbol is SNIP", function()
	{
		return crowdsale.symbol().then(function(symbol) {
      	assert.equal(symbol.valueOf(), "SNIP", "didn't get right symbol");
	});
	});
	it ("Check token name is SnipCoin", function()
	{
      	return crowdsale.name().then(function(name) {
      	assert.equal(name.valueOf(), "SnipCoin", "didn't get right token name");
	});
	});
	it ("Check decimals is 18", function()
	{
      	return crowdsale.decimals().then(function(decimals) {
      	assert.equal(decimals.valueOf(), 18, "didn't get right token name");
	});
	});
	it ("Check send tokens correctly to other account", function()
	{
		var snip = crowdsale;
		snip.setEthToUsdExchangeRate(285);

	    // Get initial balances of first and second account.
	    var account_one = accounts[0];
	    var account_two = accounts[1];

	    var account_one_starting_balance;
	    var account_two_starting_balance;
	    var account_one_ending_balance;
	    var account_two_ending_balance;

	    var amount = 10;

      	return snip.getBalance.call(account_one).then(function(balance) {
	      account_one_starting_balance = balance.toNumber();
	      return snip.getBalance.call(account_two);
	    }).then(function(balance) {
	      account_two_starting_balance = balance.toNumber();
	      return snip.transfer(account_two, amount, {from: account_one});
	    }).then(function() {
	      return snip.getBalance.call(account_one);
	    }).then(function(balance) {
	      account_one_ending_balance = balance.toNumber();
	      return snip.getBalance.call(account_two);
	    }).then(function(balance) {
	      account_two_ending_balance = balance.toNumber();

	      assert.equal(account_one_ending_balance, account_one_starting_balance - amount, "Amount wasn't correctly taken from the sender");
	      assert.equal(account_two_ending_balance, account_two_starting_balance + amount, "Amount wasn't correctly sent to the receiver");
		});
		});

		it ("Check accumulator function which counts the transfer of all tokens, before sale begins [eth count]", function()
		{
	      	return crowdsale.totalEthReceivedInWei().then(function(totalEthReceivedInWei) {
	      	assert.equal(totalEthReceivedInWei.valueOf(), 14500 * WEI_IN_ETHER, "didn't get correct eth accumulation");
		});
		});

		it ("Check accumulator function which counts the transfer of all tokens, before sale begins [usd count]", function()
		{
	      	return crowdsale.totalUsdReceived().then(function(totalUsdReceived) {
	      	assert.equal(totalUsdReceived.valueOf(), 4000000, "didn't get correct usd accumulation");
		});
		});

		it ("Check ether receival with contract, transfer to third account", function()
		{
			// Check that 
			var account_two = accounts[1];
			var snip = crowdsale;
			snip.setEthToUsdExchangeRate(285);
			snip.addAddressToCappedAddresses(account_two);

	      	return snip.totalEthReceivedInWei().then(function(totalEthReceivedInWei) {
		      assert.equal(totalEthReceivedInWei.valueOf(), 14500 * WEI_IN_ETHER, "Not starting with correct eth value");
		      return snip.totalEthReceivedInWei();
		    }).then(function(totalEthReceivedInWei) {
		    	web3.eth.sendTransaction({
		          from: account_two,
		          to: snip.address,
		          value: web3.toWei(2, 'ether'),
		          gas: 130000
		        }, function(err, res) {
		            //if (!err) return reject(new Error('Cant be here'))
		            if (!err) return;
		            assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
		        })
		        return snip.totalEthReceivedInWei();
		    }).then(function(totalEthReceivedInWei) {
		     	assert.equal(totalEthReceivedInWei.valueOf(), 14502 * WEI_IN_ETHER, "Not with correct eth value after transfer")
		     	return snip.totalUsdReceived();
		     }).then(function(totalUsdReceived) {
		     	assert.equal(totalUsdReceived.valueOf(), 4000570, "Not with correct usd value after transfer")
	    });
		});

		it ("Transfer less than $50 worth of Ether, see that it doesn't work", function()
		{
			var account_two = accounts[1];
			var snip = crowdsale;
			snip.setEthToUsdExchangeRate(285);
			snip.addAddressToCappedAddresses(account_two);

			return snip.totalEthReceivedInWei().then(function(totalEthReceivedInWei) {
		      assert.equal(totalEthReceivedInWei.valueOf(), 14502 * WEI_IN_ETHER, "Not starting with correct eth value");
		      return snip.totalEthReceivedInWei();
		    }).then(function(totalEthReceivedInWei) {
		    	web3.eth.sendTransaction({
		          from: account_two,
		          to: snip.address,
		          value: web3.toWei(0.02, 'ether'),
		          gas: 130000
		        }, function(err, res) {
		            //if (!err) return reject(new Error('Cant be here'))
		            if (!err) return;
		            assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
		        })
		        return snip.totalEthReceivedInWei();
		    }).then(function(totalEthReceivedInWei) {
		     	assert.equal(totalEthReceivedInWei.valueOf(), 14502 * WEI_IN_ETHER, "Not with correct eth value after transfer")
		     	return snip.totalUsdReceived();
		     }).then(function(totalUsdReceived) {
		     	assert.equal(totalUsdReceived.valueOf(), 4000570, "Not with correct usd value after transfer")
	    });			
		});

		it ("Transfer more than $8000000 worth of Ether, see that it doesn't work", function()
		{
			var account_two = accounts[1];
			var snip = crowdsale;
			snip.setEthToUsdExchangeRate(28500000);
			//snip.setEthToUsdExchangeRate(285);
			snip.addAddressToCappedAddresses(account_two);

			return snip.totalEthReceivedInWei().then(function(totalEthReceivedInWei) {
		      assert.equal(totalEthReceivedInWei.valueOf(), 14502 * WEI_IN_ETHER, "Not starting with correct eth value");
		      return snip.totalEthReceivedInWei();
		    }).then(function(totalEthReceivedInWei) {
		    	web3.eth.sendTransaction({
		          from: account_two,
		          to: snip.address,
		          value: web3.toWei(2, 'ether'),
		          gas: 130000
		        }, function(err, res) {
		            //if (!err) return reject(new Error('Cant be here'))
		            if (!err) return;
		            assert.equal(err.message, 'VM Exception while processing transaction: invalid opcode')
		        })
		        return snip.totalEthReceivedInWei();
		    }).then(function(totalEthReceivedInWei) {
		     	assert.equal(totalEthReceivedInWei.valueOf(), 14502 * WEI_IN_ETHER, "Not with correct eth value after transfer")
		     	return snip.totalUsdReceived();
		     }).then(function(totalUsdReceived) {
		     	assert.equal(totalUsdReceived.valueOf(), 4000570, "Not with correct usd value after transfer")
	    });	
		});

		it ("Test effective max cap, see that ends the sale", function()
		{

		});

		it ("Test update of snp/eth ratio", function()
		{

		});
});
const { expect } = require('chai')
const { ethers } = require('hardhat')

// describe("Greeter", function () {
//   it("Should return the new greeting once it's changed", async function () {
//     const Greeter = await ethers.getContractFactory("Greeter");
//     const greeter = await Greeter.deploy("Hello, world!");
//     await greeter.deployed();

//     expect(await greeter.greet()).to.equal("Hello, world!");

//     const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

//     // wait until the transaction is mined
//     await setGreetingTx.wait();

//     expect(await greeter.greet()).to.equal("Hola, mundo!");
//   });
// });

describe('Crypto Credit Card', function () {
  it('Should deploy the contracts successfully', async function () {

    const aggregatorAddress = "0x8A753747A1Fa494EC906cE90E9f37563A8AF630e"  // On Rinkeby
    const routerAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"      // On Rinkeby
    const WETHAddress = "0xc778417e063141139fce010982780140aa0cd5ab"        // On Rinkeby
  
    const TreasuryContractFactory = await ethers.getContractFactory(
      'TreasuryContract',
    )
    const treasuryContract = await TreasuryContractFactory.deploy(
      aggregatorAddress,
      routerAddress,
      WETHAddress
    )
    await treasuryContract.deployed()
    console.log('Treasure Contract Address: ' + treasuryContract.address)

    const account = await ethers.getSigner()

    const CCIssuerContractFactory = await ethers.getContractFactory('CCIssuer')
    const ccIssuerContract = await CCIssuerContractFactory.deploy(
      account.address,
      treasuryContract.address,
    )
    await ccIssuerContract.deployed()
    console.log('CCIssuer Contract Address: ' + ccIssuerContract.address)

    await treasuryContract.setCCIssuer(ccIssuerContract.address)

    const UserContract = await ccIssuerContract.issueCC(
        account.address,
        "10000"
    )
    console.log(UserContract)
  })
})

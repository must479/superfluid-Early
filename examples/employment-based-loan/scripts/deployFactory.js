const ethers = require("ethers");
const { Framework } = require("@superfluid-finance/sdk-core");
const Factory = require("../artifacts/contracts/LoanFactory.sol/LoanFactory.json");
const FactoryABI = Factory.abi;
const MOCKAggregator = require("../artifacts/contracts/test/MockV3Aggregator.sol/MockV3Aggregator.json");
const MOCK_ABI = MOCKAggregator.abi;
require("dotenv").config();

async function main() {

  const url = `${process.env.RPC_URL}`;
  const customHttpProvider = new ethers.providers.JsonRpcProvider(url);

  const sf = await Framework.create({
    chainId: process.env.CHAIN_ID,
    provider: customHttpProvider,
    customSubgraphQueriesEndpoint: "",
    dataMode: "WEB3_ONLY"
  });

  const borrower = sf.createSigner({
    privateKey:
      process.env.BORROWER_PRIVATE_KEY,
    provider: customHttpProvider
  });

  const employer = sf.createSigner({
    privateKey:
      process.env.EMPLOYER_PRIVATE_KEY,
    provider: customHttpProvider
  });

  console.log('running deploy factory script...')
  // We get the contract to deploy
  const LoanFactory = await hre.ethers.getContractFactory("LoanFactory");
  const loanFactory = await LoanFactory.connect(borrower).deploy();
  
  await loanFactory.deployed();

  console.log("LoanFactory.sol deployed to:", loanFactory.address);

  const MockV3Aggregator = await hre.ethers.getContractFactory("MockV3Aggregator");
  const mockV3Aggregator = await MockV3Aggregator.connect(borrower).deploy(10000000000);

  await mockV3Aggregator.deployed();

  console.log("MockV3Aggregator deployed to: ", mockV3Aggregator.address);
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


import { deployContract } from "./utils";

async function main() {
  const name = "RandomToken";
  const symbol = "RT";
  const price = 1;
  const maxSupply = 10;

  const randomToken = await deployContract("RandomToken", [
    "",
    name,
    symbol,
    price,
    maxSupply,
  ]);

  console.log(`RandomToken deployed to: ${randomToken.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

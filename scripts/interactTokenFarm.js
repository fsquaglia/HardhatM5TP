const { ethers } = require("ethers");
const dotenv = require("dotenv");
const tokenFarmABI = require("../artifacts/contracts/TokenFarm.sol/TokenFarm.json");

dotenv.config();

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY;
const TOKENFARM_ADDRESS = "0x..."; //! Reemplazá por tu dirección real de TokenFarm

const provider = new ethers.JsonRpcProvider(
  `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`
);
const wallet = new ethers.Wallet(SEPOLIA_PRIVATE_KEY, provider);

const tokenFarmContract = new ethers.Contract(
  TOKENFARM_ADDRESS,
  tokenFarmABI.abi,
  wallet
);

// Reclamar recompensas
async function claimRewards() {
  console.log("Reclamando recompensas...");
  const tx = await tokenFarmContract.claimRewards();
  const receipt = await tx.wait();
  console.log("Recompensas reclamadas. Tx hash:", receipt.hash);
}

// Retirar staking
async function withdraw() {
  console.log("Retirando LP tokens del staking...");
  const tx = await tokenFarmContract.withdraw();
  const receipt = await tx.wait();
  console.log("Retiro exitoso. Tx hash:", receipt.hash);
}

// Distribuir recompensas a todos los usuarios (owner)
async function distributeRewards() {
  console.log("Distribuyendo recompensas a todos los usuarios...");
  const tx = await tokenFarmContract.distributeRewardsAll();
  const receipt = await tx.wait();
  console.log("Recompensas distribuidas. Tx hash:", receipt.hash);
}

// Obtener datos del usuario
async function getUserInfo(address) {
  const user = await tokenFarmContract.users(address);
  console.log(`Info de ${address}:`);
  console.log("Staking balance:", ethers.formatEther(user.stakingBalance));
  console.log("Pending rewards:", ethers.formatEther(user.pendingRewards));
}

// Ejecutar funciones
async function main() {
  // await claimRewards();
  // await withdraw();
  // await distributeRewards();
  // await getUserInfo("0x..."); // tu wallet o cualquier address
}

main().catch((err) => {
  console.error("Error en script:", err);
});

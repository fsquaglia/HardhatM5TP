const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("TokenFarmModule", (m) => {
  // Parámetro: dirección del owner
  const owner = m.getAccount(0); // primer cuenta por defecto

  // Desplegar DAppToken con el owner como parámetro
  const dappToken = m.contract("DAppToken", [owner]);

  // Desplegar LPToken con el owner como parámetro
  const lpToken = m.contract("LPToken", [owner]);

  // Desplegar TokenFarm con las direcciones de los contratos anteriores
  const tokenFarm = m.contract("TokenFarm", [dappToken, lpToken]);

  return { dappToken, lpToken, tokenFarm };
});

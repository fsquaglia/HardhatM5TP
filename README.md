# TokenFarm - DeFi Yield Farming

## Requisitos

- Node.js
- Hardhat con Ethers.js
- Alchemy
- Cuenta en Sepolia con ETH

## Configuración

1. Instalar dependencias:

```bash
npm install
```

2. Agregar variables a .env para un deploy en Sepolia

```bash
ALCHEMY_API_KEY=""
SEPOLIA_PRIVATE_KEY=""
ETHERSCAN_API_KEY=""
```

3. Compilar

```bash
npx hardhat compile
```

4. Testear

```bash
npx hardhat test
```

5. Deployar en Sepolia

```bash
npx hardhat run ignition/modules/TokenFarm.js --network sepolia
```

6. Interactuar

##### Editar el archivo scripts/interactTokenFarm.js comentando y descomentando las líneas necesarias dentro de la función:

"async function main() {...}"

##### Modificar la variable TOKENFARM_ADDRESS con el contrato deployado por el usuario

Correr con:

```bash
npx hardhat run scripts/interactTokenFarm.js
```

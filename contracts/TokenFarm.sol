// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./DAppToken.sol";
import "./LPToken.sol";

/**
 * @title Proportional Token Farm
 * @notice Una granja de staking donde las recompensas se distribuyen proporcionalmente al total stakeado.
 * @dev Este contrato permite a los usuarios depositar tokens LP, recibir recompensas en DappToken
 *       y retirar sus tokens LP. Las recompensas se calculan en función del porcentaje de tokens
 *       que cada usuario tiene en staking con respecto al total de tokens en staking.
 */
contract TokenFarm {
    //
    // Variables de estado
    //
    string public name = "Proportional Token Farm";
    address public owner;
    DAppToken public dappToken;
    LPToken public lpToken;

    // uint256 public constant REWARD_PER_BLOCK = 1e18; // Recompensa por bloque (total para todos los usuarios)
    // ** Agregado para bonus 4 **
    // Rango de recompensa por bloque
    uint256 public rewardPerBlock;
    uint256 public immutable minRewardPerBlock = 1e17; // 0.1 DAPP
    uint256 public immutable maxRewardPerBlock = 10e18; // 10 DAPP
    // ** Agregado para bonus 5 **
    uint256 public feePercent = 10; // comisión del 10%
    uint256 public totalFeesCollected;


    uint256 public totalStakingBalance; // Total de tokens en staking

    address[] public stakers;
    // mapping(address => uint256) public stakingBalance;
    // mapping(address => uint256) public checkpoints;
    // mapping(address => uint256) public pendingRewards;
    // mapping(address => bool) public hasStaked;
    // mapping(address => bool) public isStaking;

    // Modificadores
    // Estos modificadores se utilizan para restringir el acceso a ciertas funciones del contrato.
    modifier onlyStaker() {
    require(users[msg.sender].isStaking, "No estas haciendo staking");
    _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el owner puede distribuir recompensas");
        _;
    }


    // Eventos
    // Agregar eventos para Deposit, Withdraw, RewardsClaimed y RewardsDistributed.
     event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDistributed();

    struct User {
        uint256 stakingBalance;
        uint256 checkpoint;
        uint256 pendingRewards;
        bool hasStaked;
        bool isStaking;
    }
    mapping(address => User) public users;

    // Constructor
    constructor(DAppToken _dappToken, LPToken _lpToken) {
        // Configurar las instancias de los contratos de DappToken y LPToken.
        dappToken = _dappToken;
        lpToken = _lpToken;
        // Configurar al owner del contrato como el creador de este contrato.
        owner = msg.sender;
        // ** Agregado para bonus 4 **
        // Establecer la recompensa por bloque inicial.
        rewardPerBlock = 1e18; // 1 DAPP por bloque
    }

    // ** Agregado para bonus 4 **
    // Establece la recompensa por bloque.
    // _newReward Nueva recompensa por bloque.
        function setRewardPerBlock(uint256 _newReward) external onlyOwner {
        require(_newReward >= minRewardPerBlock && _newReward <= maxRewardPerBlock, "Reward fuera de rango permitido");
        rewardPerBlock = _newReward;
    }


    /**
     * @notice Deposita tokens LP para staking.
     * @param _amount Cantidad de tokens LP a depositar.
     */
    function deposit(uint256 _amount) external {
        // Verificar que _amount sea mayor a 0.
        require(_amount > 0, "La cantidad debe ser mayor que 0");
        // Transferir tokens LP del usuario a este contrato.
        distributeRewards(msg.sender);
        lpToken.transferFrom(msg.sender, address(this), _amount);
        // Actualizar el balance de staking del usuario en stakingBalance.
         users[msg.sender].stakingBalance += _amount;
        // Incrementar totalStakingBalance con _amount.
        totalStakingBalance += _amount;
        // Si el usuario nunca ha hecho staking antes, agregarlo al array stakers y marcar hasStaked como true.
        if (!users[msg.sender].hasStaked) {
            stakers.push(msg.sender);
            users[msg.sender].hasStaked = true;
        }
        // Actualizar isStaking del usuario a true.
        users[msg.sender].isStaking = true;
        // Si checkpoints del usuario está vacío, inicializarlo con el número de bloque actual.
        if (users[msg.sender].checkpoint == 0) {
            users[msg.sender].checkpoint = block.number;
        }
        // Llamar a distributeRewards para calcular y actualizar las recompensas pendientes.
        distributeRewards(msg.sender);
        // Emitir un evento de depósito.
        emit Deposit(msg.sender, _amount);
    }


    /**
     * @notice Retira todos los tokens LP en staking.
     */
    function withdraw() external onlyStaker  {
        // Verificar que el usuario está haciendo staking (isStaking == true).
        //? require(users[msg.sender].isStaking, "No estas haciendo staking");        
        // Obtener el balance de staking del usuario.
        uint256 balance = users[msg.sender].stakingBalance;
        // Verificar que el balance de staking sea mayor a 0.
        require(balance > 0, "No tienes tokens para retirar");
        // Llamar a distributeRewards para calcular y actualizar las recompensas pendientes antes de restablecer el balance.
        distributeRewards(msg.sender);
        // Restablecer stakingBalance del usuario a 0.
         users[msg.sender].stakingBalance = 0;
        // Reducir totalStakingBalance en el balance que se está retirando.
        totalStakingBalance -= balance;
        // Actualizar isStaking del usuario a false.
        	users[msg.sender].isStaking = false;
        // Transferir los tokens LP de vuelta al usuario.
        lpToken.transfer(msg.sender, balance);
        // Emitir un evento de retiro.
        emit Withdraw(msg.sender, balance);
    }

    /**
     * @notice Reclama recompensas pendientes.
     */
    function claimRewards() external onlyStaker {
        // Obtener el monto de recompensas pendientes del usuario desde pendingRewards.
        uint256 pendingAmount = users[msg.sender].pendingRewards;
        // Verificar que el monto de recompensas pendientes sea mayor a 0.
        require(pendingAmount > 0, "No tienes recompensas pendientes");        
        // Restablecer las recompensas pendientes del usuario a 0.
        users[msg.sender].pendingRewards = 0;
        // ** Agregado para bonus 5 **
        // Calcular la comisión a cobrar.
        uint256 fee = (pendingAmount * feePercent) / 100;
        uint256 netReward = pendingAmount - fee;
        totalFeesCollected += fee;

        // Llamar a la función de acuñación (mint) en el contrato DappToken para transferir las recompensas al usuario.
        dappToken.mint(msg.sender, netReward);
        // Emitir un evento de reclamo de recompensas.
        emit RewardsClaimed(msg.sender, netReward);
    }

    /**
     * @notice Distribuye recompensas a todos los usuarios en staking.
     */
    function distributeRewardsAll() external onlyOwner {
        // Verificar que la llamada sea realizada por el owner.
        // ? require(msg.sender == owner, "Solo el owner puede distribuir recompensas");
        // Iterar sobre todos los usuarios en staking almacenados en el array stakers.
        for (uint256 i = 0; i < stakers.length; i++) {
            address beneficiary = stakers[i];
            // Verificar que el usuario está haciendo staking (isStaking == true).
            if (users[beneficiary].isStaking) {
            // Llamar a distributeRewards para cada usuario.
            distributeRewards(beneficiary);
            }
        }
        // Emitir un evento indicando que las recompensas han sido distribuidas.
        emit RewardsDistributed();
    }

    /**
     * @notice Calcula y distribuye las recompensas proporcionalmente al staking total.
     * @dev La función toma en cuenta el porcentaje de tokens que cada usuario tiene en staking con respecto
     *      al total de tokens en staking (`totalStakingBalance`).
     *
     * Funcionamiento:
     * 1. Se calcula la cantidad de bloques transcurridos desde el último checkpoint del usuario.
     * 2. Se calcula la participación proporcional del usuario:
     *    share = stakingBalance[beneficiary] / totalStakingBalance
     * 3. Las recompensas para el usuario se determinan multiplicando su participación proporcional
     *    por las recompensas por bloque (`REWARD_PER_BLOCK`) y los bloques transcurridos:
     *    reward = REWARD_PER_BLOCK * blocksPassed * share
     * 4. Se acumulan las recompensas calculadas en `pendingRewards[beneficiary]`.
     * 5. Se actualiza el checkpoint del usuario al bloque actual.
     *
     * Ejemplo Práctico:
     * - Supongamos que:
     *    Usuario A ha stakeado 100 tokens.
     *    Usuario B ha stakeado 300 tokens.
     *    Total de staking (`totalStakingBalance`) = 400 tokens.
     *    `REWARD_PER_BLOCK` = 1e18 (1 token total por bloque).
     *    Han transcurrido 10 bloques desde el último checkpoint.
     *
     * Cálculo:
     * - Participación de Usuario A:
     *   shareA = 100 / 400 = 0.25 (25%)
     *   rewardA = 1e18 * 10 * 0.25 = 2.5e18 (2.5 tokens).
     *
     * - Participación de Usuario B:
     *   shareB = 300 / 400 = 0.75 (75%)
     *   rewardB = 1e18 * 10 * 0.75 = 7.5e18 (7.5 tokens).
     *
     * Resultado:
     * - Usuario A acumula 2.5e18 en `pendingRewards`.
     * - Usuario B acumula 7.5e18 en `pendingRewards`.
     *
     * Nota:
     * Este sistema asegura que las recompensas se distribuyan proporcionalmente y de manera justa
     * entre todos los usuarios en función de su contribución al staking total.
     */
    function distributeRewards(address beneficiary) private {
        // Obtener el último checkpoint del usuario desde checkpoints.
        uint256 lastCheckpoint = users[beneficiary].checkpoint;
        // Verificar que el número de bloque actual sea mayor al checkpoint y que totalStakingBalance sea mayor a 0.
        if (block.number <= lastCheckpoint || totalStakingBalance == 0) {
            return;
        }
        // Calcular la cantidad de bloques transcurridos desde el último checkpoint.
        uint256 blocksPassed = block.number - lastCheckpoint;
        // Calcular la proporción del staking del usuario en relación al total staking (stakingBalance[beneficiary] / totalStakingBalance).
        uint256 userStaking = users[beneficiary].stakingBalance;
        uint256 share = (userStaking * 1e18) / totalStakingBalance; 
        // Calcular las recompensas del usuario multiplicando la proporción por REWARD_PER_BLOCK y los bloques transcurridos.
        uint256 reward = (rewardPerBlock * blocksPassed * share) / 1e18; 
        // Actualizar las recompensas pendientes del usuario en pendingRewards.
        users[beneficiary].pendingRewards += reward;
        // Actualizar el checkpoint del usuario al bloque actual.
        users[beneficiary].checkpoint = block.number;
    }

    // ** Agregado para bonus 5 **
    /**
     * @notice Retira las comisiones acumuladas y las transfiere al owner.
     * @dev Esta función solo puede ser llamada por el owner del contrato.
    * Asegura que haya comisiones acumuladas antes de realizar el retiro.
    */
    function withdrawFees() external onlyOwner {
    require(totalFeesCollected > 0, "No hay comisiones acumuladas");
    uint256 amount = totalFeesCollected;
    totalFeesCollected = 0;
    dappToken.mint(owner, amount);
}

}
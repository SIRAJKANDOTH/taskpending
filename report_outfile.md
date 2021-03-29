## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| contracts/aishToken.sol | a272ba06753f28115b218538d22ca1a383f78805 |
| contracts/Migrations.sol | 386c250290b0ed66d6b9dfffd3bba685014993c1 |
| contracts/StrategySmartDeposit.sol | e3e5a8eca5d932167e68d9befbc9a8a0bb35d3be |
| contracts/YieldsterVault.sol | b81f0fa1dd47b56c915752d0771b825a71069799 |
| contracts/yrToken.sol | b13f1a2128f934b07af992f7057de5234d55c82b |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **aishToken** | Implementation | ERC20 |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
||||||
| **Migrations** | Implementation |  |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | setCompleted | Public ❗️ | 🛑  | restricted |
| └ | upgrade | Public ❗️ | 🛑  | restricted |
||||||
| **StrategySmartDeposit** | Implementation |  |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | getName | External ❗️ |   |NO❗️ |
| └ | smartDeposit | Public ❗️ |   |NO❗️ |
||||||
| **YieldsterVault** | Implementation | VaultStorage |||
| └ | enableEmergencyBreak | Public ❗️ | 🛑  |NO❗️ |
| └ | disableEmergencyBreak | Public ❗️ | 🛑  |NO❗️ |
| └ | enableEmergencyExit | Public ❗️ | 🛑  |NO❗️ |
| └ | _onlyNormalMode | Private 🔐 |   | |
| └ | isWhiteListed | Private 🔐 |   | |
| └ | setup | Public ❗️ | 🛑  |NO❗️ |
| └ | registerVaultWithAPS | Public ❗️ | 🛑  | onlyNormalMode |
| └ | setVaultAssets | Public ❗️ | 🛑  | onlyNormalMode |
| └ | setVaultStrategyAndProtocol | Public ❗️ | 🛑  | onlyNormalMode |
| └ | disableVaultStrategy | Public ❗️ | 🛑  | onlyNormalMode |
| └ | setVaultActiveStrategy | Public ❗️ | 🛑  | onlyNormalMode |
| └ | deactivateVaultStrategy | Public ❗️ | 🛑  | onlyNormalMode |
| └ | getVaultActiveStrategy | Public ❗️ |   |NO❗️ |
| └ | setVaultSmartStrategy | Public ❗️ | 🛑  |NO❗️ |
| └ | changeAPSManager | Public ❗️ | 🛑  | onlyNormalMode |
| └ | changeStrategyManager | Public ❗️ | 🛑  | onlyNormalMode |
| └ | deposit | Public ❗️ | 🛑  | onlyNormalMode onlyWhitelisted |
| └ | withdraw | Public ❗️ | 🛑  | onlyNormalMode onlyWhitelisted |
| └ | withdraw | Public ❗️ | 🛑  | onlyNormalMode onlyWhitelisted |
| └ | earn | Public ❗️ | 🛑  | onlyNormalMode |
| └ | safeCleanUp | Public ❗️ | 🛑  |NO❗️ |
| └ | onERC1155Received | External ❗️ | 🛑  | onlyNormalMode |
| └ | onERC1155BatchReceived | External ❗️ | 🛑  |NO❗️ |
| └ | managementFeeCleanUp | Private 🔐 | 🛑  | |
||||||
| **yrToken** | Implementation | ERC20 |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |

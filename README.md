# Story Governance Transaction Generator

This repository contains a script to generate governance transactions for the Story protocol, referenced in SIPs.
It uses foundry script to generate the raw transactions so the community and signers can verify them

## 1. Install `npm` if you haven't.

## 2. Pull `node_modules`.

```
npm install -g pnpm
pnpm install
```

## 3. Install `foundry`.

```
curl -L https://foundry.paradigm.xyz | bash
source ~/.bash_profile
foundryup
```

## 4. Set the necessary environmental values in .env file in root folder


## 5. Write a Foundry script to generate the transactions.

Since admin transactions are timelocked in Story, for execution they have to be scheduled and executed after a delay.
To help properly encode the transaction and be a source of truth for the community, we developed helper contracts.

`JSONTxHelper` will generate a JSON file with the transactions and store them in the `script/admin-actions/output/<chainId>` folder.

## 5.1 Story Network Contract Timelock

1. Inherit from `JSONTimelockedOperations`
2. Set the `from` address to the admin address
3. Set the `Modes` to `Modes.SCHEDULE`, `Modes.EXECUTE` or `Modes.CANCEL`
- `Modes.SCHEDULE`: Governance process will schedule the transaction to be executed after a delay
- `Modes.EXECUTE`: Execution is public on Story mainnet to ensure the governance process can be executed by any address.
- `Modes.CANCEL`: In order to block scheduled erroneous or malicious transactions, a Security Council is being constituted, which controls a 
wallet with the CANCELLER/Guardian role. The role allows cancelling scheduled transactions during the timelock period.
5. Run the script.

```
forge script script/admin-actions/<script_name>.s.sol -vvvv --rpc-url <RPC_URL>
```

## 5.2 Proof of Creativity Protocol Guardian

// TODO
# BITVOLT Smart Contract

[<img src="https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white">](https://github.com/Bit-Volt/bitvolt-sc)

## Installtion 
```shell
npm i
```

## Reference Commands
```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node

# Deploy and verify
npx hardhat run --network hardhat scripts/deploy.js
npx hardhat verify --network testnet --constructor-args ./scripts/arguments.js <contract_addr>

# Deploy and verify repeatedly
export CADDR=$(npx hardhat run --network testnet scripts/deploy.js | tail -n 1 | cut -d: -f2)
npx hardhat  verify --network testnet --constructor-args ./scripts/arguments.js $CADDR
```

## Environment file 
`<rootdir>/.env`
```shell
AC_PRIV_KEY=
AC_ADDRESS=
API_KEY_ALCHEMY_KOVAN=
API_BSCSCAN=
```

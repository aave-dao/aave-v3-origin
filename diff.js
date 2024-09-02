#!/usr/bin/env node

import { ethers } from "ethers";
import { CONTRACTS, PROXIES, CHAIN_ID } from "./diff_config.js";
import child_process from "child_process";
import dotenv from "dotenv";
import fs from "fs";
dotenv.config();

function runCmd(cmd) {
  var resp = child_process.execSync(cmd);
  var result = resp.toString("UTF8");
  return result;
}

const API_KEYS = {
  mainnet: process.env.ETHERSCAN_API_KEY_MAINNET,
};

function download(network, contractName, address) {
  if (!fs.existsSync(`downloads/${network}/${contractName}`)) {
    console.log("downloading", contractName);
    runCmd(
      `cast etherscan-source --chain-id ${CHAIN_ID[network]} -d downloads/${network}/${contractName} ${address} --etherscan-api-key ${API_KEYS.mainnet}`
    );
  }
}

function getImpl(network, address) {
  return ethers.toQuantity(
    runCmd(
      `cast storage --rpc-url mainnet ${address} 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
    ).replace("\n", ""),
    32
  );
}

function diffContracts(commonContracts, network1, network2) {
  try {
    commonContracts.map((contractName) => {
      PROXIES.includes(contractName) && (contractName = contractName + "_IMPL");
      const sourcePathNetwork1 =
        network1 != "FACTORY_LOCAL"
          ? `./downloads/${network1}/${contractName}.sol`
          : `./downloads/FACTORY_LOCAL/${contractName}.sol`;
      const sourcePathNetwork2 =
        network2 != "FACTORY_LOCAL"
          ? `./downloads/${network2}/${contractName}.sol`
          : `./downloads/FACTORY_LOCAL/${contractName}.sol`;
      const outPath = `${network1}_${network2}/${contractName}_DIFF`;
      runCmd(
        `make git-diff before=${sourcePathNetwork1} after=${sourcePathNetwork2} out=${outPath}`
      );
    });
  } catch (e) {
    console.log(e);
    throw new Error("oops... failed to diff contracts");
  }
}

function flatten(network, name, path) {
  console.log("flattening contract", name);
  const sourcePath =
    network != "FACTORY_LOCAL"
      ? `./downloads/${network}/${name}/${path}`
      : `./${path}`;
  const outPath =
    network != "FACTORY_LOCAL"
      ? `./downloads/${network}/${name}.sol`
      : `./downloads/FACTORY_LOCAL/${name}.sol`;
  runCmd(`forge flatten ${sourcePath} --output ${outPath}`);
}

function downloadContracts(commonContracts, network) {
  commonContracts.map((key) => {
    const isProxy = PROXIES.includes(key);
    const contractName = isProxy ? `${key}_IMPL` : key;
    const address = isProxy
      ? getImpl(network.toLowerCase(), CONTRACTS[network][key].address)
      : CONTRACTS[network][key].address;
    download(network, contractName, address);
  });
}

function flattenContracts(commonContracts, network) {
  commonContracts.map((key) => {
    const isProxy = PROXIES.includes(key);
    const contractName = isProxy ? `${key}_IMPL` : key;
    flatten(network, contractName, CONTRACTS[network][key].path);
  });
}

function prettifyContracts() {
  runCmd(`npm run lint:fix`);
}

async function main() {
  // get networks to diff against from the command line input
  const network1 = process.argv[2];
  const network2 = process.argv[3];

  console.log(`comparing diffs between ${network1}, ${network2}`);

  // find all the common contracts to compare between both the networks.
  const commonContracts = Object.keys(CONTRACTS[network1]).filter((key) =>
    CONTRACTS[network2].hasOwnProperty(key)
  );

  if (network1 != "FACTORY_LOCAL") {
    downloadContracts(commonContracts, network1);
  }
  if (network2 != "FACTORY_LOCAL") {
    downloadContracts(commonContracts, network2);
  }

  flattenContracts(commonContracts, network1);
  flattenContracts(commonContracts, network2);

  prettifyContracts();

  diffContracts(commonContracts, network1, network2);
}

main();

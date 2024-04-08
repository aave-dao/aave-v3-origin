# To load the variables in the .env file
source .env

# To deploy and verify our contract
forge script script/DeployTransparentProxyFactory.s.sol:Deploy --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv

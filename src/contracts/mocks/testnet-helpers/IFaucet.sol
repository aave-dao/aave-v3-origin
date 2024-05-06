// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFaucet {
  /**
   * @notice Function to mint Testnet tokens to the destination address
   * @param token The address of the token to perform the mint
   * @param to The address to send the minted tokens
   * @param amount The amount of tokens to mint
   * @return The amount minted
   **/
  function mint(address token, address to, uint256 amount) external returns (uint256);

  /**
   * @notice Enable or disable the need of authentication to call `mint` function
   * @param value If true, ask for authentication at `mint` function, if false, disable the authentication
   */
  function setPermissioned(bool value) external;

  /**
   * @notice Getter to determine if permissioned mode is enabled or disabled
   * @return Returns a boolean, if true the mode is enabled, if false is disabled
   */
  function isPermissioned() external view returns (bool);

  /**
   * @notice Transfer the ownership of child contracts
   * @param childContracts A list of child contract addresses
   * @param newOwner The address of the new owner
   */
  function transferOwnershipOfChild(address[] calldata childContracts, address newOwner) external;
}

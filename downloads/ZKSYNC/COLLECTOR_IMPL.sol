// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ^0.8.10;

// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/core/contracts/dependencies/openzeppelin/contracts/Address.sol

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, 'Address: low-level call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    require(isContract(target), 'Address: call to non-contract');

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data
  ) internal view returns (bytes memory) {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), 'Address: static call to non-contract');

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: delegate call to non-contract');

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/core/contracts/dependencies/openzeppelin/contracts/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/core/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol

/**
 * @title VersionedInitializable
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 private lastInitializedRevision = 0;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(
      initializing || isConstructor() || revision > lastInitializedRevision,
      'Contract instance has already been initialized'
    );

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      lastInitializedRevision = revision;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /**
   * @notice Returns the revision number of the contract
   * @dev Needs to be defined in the inherited class as a constant.
   * @return The revision number
   */
  function getRevision() internal pure virtual returns (uint256);

  /**
   * @notice Returns true if and only if the function is running in the constructor
   * @return True if the function is running in the constructor
   */
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/periphery/contracts/dependencies/openzeppelin/ReentrancyGuard.sol

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  /**
   * @dev As we use the guard with the proxy we need to init it with the empty value
   */
  function _initGuard() internal {
    _status = _NOT_ENTERED;
  }
}

// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/periphery/contracts/treasury/ICollector.sol

interface ICollector {
  struct Stream {
    uint256 deposit;
    uint256 ratePerSecond;
    uint256 remainingBalance;
    uint256 startTime;
    uint256 stopTime;
    address recipient;
    address sender;
    address tokenAddress;
    bool isEntity;
  }

  /** @notice Emitted when the funds admin changes
   * @param fundsAdmin The new funds admin.
   **/
  event NewFundsAdmin(address indexed fundsAdmin);

  /** @notice Emitted when the new stream is created
   * @param streamId The identifier of the stream.
   * @param sender The address of the collector.
   * @param recipient The address towards which the money is streamed.
   * @param deposit The amount of money to be streamed.
   * @param tokenAddress The ERC20 token to use as streaming currency.
   * @param startTime The unix timestamp for when the stream starts.
   * @param stopTime The unix timestamp for when the stream stops.
   **/
  event CreateStream(
    uint256 indexed streamId,
    address indexed sender,
    address indexed recipient,
    uint256 deposit,
    address tokenAddress,
    uint256 startTime,
    uint256 stopTime
  );

  /**
   * @notice Emmitted when withdraw happens from the contract to the recipient's account.
   * @param streamId The id of the stream to withdraw tokens from.
   * @param recipient The address towards which the money is streamed.
   * @param amount The amount of tokens to withdraw.
   */
  event WithdrawFromStream(uint256 indexed streamId, address indexed recipient, uint256 amount);

  /**
   * @notice Emmitted when the stream is canceled.
   * @param streamId The id of the stream to withdraw tokens from.
   * @param sender The address of the collector.
   * @param recipient The address towards which the money is streamed.
   * @param senderBalance The sender's balance at the moment of cancelling.
   * @param recipientBalance The recipient's balance at the moment of cancelling.
   */
  event CancelStream(
    uint256 indexed streamId,
    address indexed sender,
    address indexed recipient,
    uint256 senderBalance,
    uint256 recipientBalance
  );

  /** @notice Returns the mock ETH reference address
   * @return address The address
   **/
  function ETH_MOCK_ADDRESS() external pure returns (address);

  /** @notice Initializes the contracts
   * @param fundsAdmin Funds admin address
   * @param nextStreamId StreamId to set, applied if greater than 0
   **/
  function initialize(address fundsAdmin, uint256 nextStreamId) external;

  /**
   * @notice Return the funds admin, only entity to be able to interact with this contract (controller of reserve)
   * @return address The address of the funds admin
   **/
  function getFundsAdmin() external view returns (address);

  /**
   * @notice Returns the available funds for the given stream id and address.
   * @param streamId The id of the stream for which to query the balance.
   * @param who The address for which to query the balance.
   * @notice Returns the total funds allocated to `who` as uint256.
   */
  function balanceOf(uint256 streamId, address who) external view returns (uint256 balance);

  /**
   * @dev Function for the funds admin to give ERC20 allowance to other parties
   * @param token The address of the token to give allowance from
   * @param recipient Allowance's recipient
   * @param amount Allowance to approve
   **/
  function approve(IERC20 token, address recipient, uint256 amount) external;

  /**
   * @notice Function for the funds admin to transfer ERC20 tokens to other parties
   * @param token The address of the token to transfer
   * @param recipient Transfer's recipient
   * @param amount Amount to transfer
   **/
  function transfer(IERC20 token, address recipient, uint256 amount) external;

  /**
   * @dev Transfer the ownership of the funds administrator role.
          This function should only be callable by the current funds administrator.
   * @param admin The address of the new funds administrator
   */
  function setFundsAdmin(address admin) external;

  /**
   * @notice Creates a new stream funded by this contracts itself and paid towards `recipient`.
   * @param recipient The address towards which the money is streamed.
   * @param deposit The amount of money to be streamed.
   * @param tokenAddress The ERC20 token to use as streaming currency.
   * @param startTime The unix timestamp for when the stream starts.
   * @param stopTime The unix timestamp for when the stream stops.
   * @return streamId the uint256 id of the newly created stream.
   */
  function createStream(
    address recipient,
    uint256 deposit,
    address tokenAddress,
    uint256 startTime,
    uint256 stopTime
  ) external returns (uint256 streamId);

  /**
   * @notice Returns the stream with all its properties.
   * @dev Throws if the id does not point to a valid stream.
   * @param streamId The id of the stream to query.
   * @notice Returns the stream object.
   */
  function getStream(
    uint256 streamId
  )
    external
    view
    returns (
      address sender,
      address recipient,
      uint256 deposit,
      address tokenAddress,
      uint256 startTime,
      uint256 stopTime,
      uint256 remainingBalance,
      uint256 ratePerSecond
    );

  /**
   * @notice Withdraws from the contract to the recipient's account.
   * @param streamId The id of the stream to withdraw tokens from.
   * @param amount The amount of tokens to withdraw.
   * @return bool Returns true if successful.
   */
  function withdrawFromStream(uint256 streamId, uint256 amount) external returns (bool);

  /**
   * @notice Cancels the stream and transfers the tokens back on a pro rata basis.
   * @param streamId The id of the stream to cancel.
   * @return bool Returns true if successful.
   */
  function cancelStream(uint256 streamId) external returns (bool);

  /**
   * @notice Returns the next available stream id
   * @return nextStreamId Returns the stream id.
   */
  function getNextStreamId() external view returns (uint256);
}

// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/core/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(oldAllowance >= value, 'SafeERC20: decreased allowance below zero');
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(
        token,
        abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
      );
    }
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// downloads/ZKSYNC/COLLECTOR_IMPL/Collector/src/periphery/contracts/treasury/Collector.sol

/**
 * @title Collector
 * @notice Stores ERC20 tokens of an ecosystem reserve and allows to dispose of them via approval
 * or transfer dynamics or streaming capabilities.
 * Modification of Sablier https://github.com/sablierhq/sablier/blob/develop/packages/protocol/contracts/Sablier.sol
 * Original can be found also deployed on https://etherscan.io/address/0xCD18eAa163733Da39c232722cBC4E8940b1D8888
 * Modifications:
 * - Sablier "pulls" the funds from the creator of the stream at creation. In the Aave case, we already have the funds.
 * - Anybody can create streams on Sablier. Here, only the funds admin (Aave governance via controller) can
 * - Adapted codebase to Solidity 0.8.11, mainly removing SafeMath and CarefulMath to use native safe math
 * - Same as with creation, on Sablier the `sender` and `recipient` can cancel a stream. Here, only fund admin and recipient
 * @author BGD Labs
 **/
contract Collector is VersionedInitializable, ICollector, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using Address for address payable;

  /*** Storage Properties ***/

  /**
   * @notice Address of the current funds admin.
   */
  address internal _fundsAdmin;

  /**
   * @notice Current revision of the contract.
   */
  uint256 public constant REVISION = 5;

  /**
   * @notice Counter for new stream ids.
   */
  uint256 private _nextStreamId;

  /**
   * @notice The stream objects identifiable by their unsigned integer ids.
   */
  mapping(uint256 => Stream) private _streams;

  /// @inheritdoc ICollector
  address public constant ETH_MOCK_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /*** Modifiers ***/

  /**
   * @dev Throws if the caller is not the funds admin.
   */
  modifier onlyFundsAdmin() {
    require(msg.sender == _fundsAdmin, 'ONLY_BY_FUNDS_ADMIN');
    _;
  }

  /**
   * @dev Throws if the caller is not the funds admin of the recipient of the stream.
   * @param streamId The id of the stream to query.
   */
  modifier onlyAdminOrRecipient(uint256 streamId) {
    require(
      msg.sender == _fundsAdmin || msg.sender == _streams[streamId].recipient,
      'caller is not the funds admin or the recipient of the stream'
    );
    _;
  }

  /**
   * @dev Throws if the provided id does not point to a valid stream.
   */
  modifier streamExists(uint256 streamId) {
    require(_streams[streamId].isEntity, 'stream does not exist');
    _;
  }

  /*** Contract Logic Starts Here */

  /// @inheritdoc ICollector
  function initialize(address fundsAdmin, uint256 nextStreamId) external initializer {
    if (nextStreamId != 0) {
      _nextStreamId = nextStreamId;
    }

    _setFundsAdmin(fundsAdmin);
  }

  /*** View Functions ***/

  /// @inheritdoc VersionedInitializable
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  /// @inheritdoc ICollector
  function getFundsAdmin() external view returns (address) {
    return _fundsAdmin;
  }

  /// @inheritdoc ICollector
  function getNextStreamId() external view returns (uint256) {
    return _nextStreamId;
  }

  /// @inheritdoc ICollector
  function getStream(
    uint256 streamId
  )
    external
    view
    streamExists(streamId)
    returns (
      address sender,
      address recipient,
      uint256 deposit,
      address tokenAddress,
      uint256 startTime,
      uint256 stopTime,
      uint256 remainingBalance,
      uint256 ratePerSecond
    )
  {
    sender = _streams[streamId].sender;
    recipient = _streams[streamId].recipient;
    deposit = _streams[streamId].deposit;
    tokenAddress = _streams[streamId].tokenAddress;
    startTime = _streams[streamId].startTime;
    stopTime = _streams[streamId].stopTime;
    remainingBalance = _streams[streamId].remainingBalance;
    ratePerSecond = _streams[streamId].ratePerSecond;
  }

  /**
   * @notice Returns either the delta in seconds between `block.timestamp` and `startTime` or
   *  between `stopTime` and `startTime, whichever is smaller. If `block.timestamp` is before
   *  `startTime`, it returns 0.
   * @dev Throws if the id does not point to a valid stream.
   * @param streamId The id of the stream for which to query the delta.
   * @notice Returns the time delta in seconds.
   */
  function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {
    Stream memory stream = _streams[streamId];
    if (block.timestamp <= stream.startTime) return 0;
    if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
    return stream.stopTime - stream.startTime;
  }

  struct BalanceOfLocalVars {
    uint256 recipientBalance;
    uint256 withdrawalAmount;
    uint256 senderBalance;
  }

  /// @inheritdoc ICollector
  function balanceOf(
    uint256 streamId,
    address who
  ) public view streamExists(streamId) returns (uint256 balance) {
    Stream memory stream = _streams[streamId];
    BalanceOfLocalVars memory vars;

    uint256 delta = deltaOf(streamId);
    vars.recipientBalance = delta * stream.ratePerSecond;

    /*
     * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
     * We have to subtract the total amount withdrawn from the amount of money that has been
     * streamed until now.
     */
    if (stream.deposit > stream.remainingBalance) {
      vars.withdrawalAmount = stream.deposit - stream.remainingBalance;
      vars.recipientBalance = vars.recipientBalance - vars.withdrawalAmount;
    }

    if (who == stream.recipient) return vars.recipientBalance;
    if (who == stream.sender) {
      vars.senderBalance = stream.remainingBalance - vars.recipientBalance;
      return vars.senderBalance;
    }
    return 0;
  }

  /*** Public Effects & Interactions Functions ***/

  /// @inheritdoc ICollector
  function approve(IERC20 token, address recipient, uint256 amount) external onlyFundsAdmin {
    token.safeApprove(recipient, amount);
  }

  /// @inheritdoc ICollector
  function transfer(IERC20 token, address recipient, uint256 amount) external onlyFundsAdmin {
    require(recipient != address(0), 'INVALID_0X_RECIPIENT');

    if (address(token) == ETH_MOCK_ADDRESS) {
      payable(recipient).sendValue(amount);
    } else {
      token.safeTransfer(recipient, amount);
    }
  }

  /// @inheritdoc ICollector
  function setFundsAdmin(address admin) external onlyFundsAdmin {
    _setFundsAdmin(admin);
  }

  /**
   * @dev Transfer the ownership of the funds administrator role.
   * @param admin The address of the new funds administrator
   */
  function _setFundsAdmin(address admin) internal {
    _fundsAdmin = admin;
    emit NewFundsAdmin(admin);
  }

  struct CreateStreamLocalVars {
    uint256 duration;
    uint256 ratePerSecond;
  }

  /// @inheritdoc ICollector
  /**
   * @dev Throws if the recipient is the zero address, the contract itself or the caller.
   *  Throws if the deposit is 0.
   *  Throws if the start time is before `block.timestamp`.
   *  Throws if the stop time is before the start time.
   *  Throws if the duration calculation has a math error.
   *  Throws if the deposit is smaller than the duration.
   *  Throws if the deposit is not a multiple of the duration.
   *  Throws if the rate calculation has a math error.
   *  Throws if the next stream id calculation has a math error.
   *  Throws if the contract is not allowed to transfer enough tokens.
   *  Throws if there is a token transfer failure.
   */
  function createStream(
    address recipient,
    uint256 deposit,
    address tokenAddress,
    uint256 startTime,
    uint256 stopTime
  ) external onlyFundsAdmin returns (uint256) {
    require(recipient != address(0), 'stream to the zero address');
    require(recipient != address(this), 'stream to the contract itself');
    require(recipient != msg.sender, 'stream to the caller');
    require(deposit > 0, 'deposit is zero');
    require(startTime >= block.timestamp, 'start time before block.timestamp');
    require(stopTime > startTime, 'stop time before the start time');

    CreateStreamLocalVars memory vars;
    vars.duration = stopTime - startTime;

    /* Without this, the rate per second would be zero. */
    require(deposit >= vars.duration, 'deposit smaller than time delta');

    /* This condition avoids dealing with remainders */
    require(deposit % vars.duration == 0, 'deposit not multiple of time delta');

    vars.ratePerSecond = deposit / vars.duration;

    /* Create and store the stream object. */
    uint256 streamId = _nextStreamId;
    _streams[streamId] = Stream({
      remainingBalance: deposit,
      deposit: deposit,
      isEntity: true,
      ratePerSecond: vars.ratePerSecond,
      recipient: recipient,
      sender: address(this),
      startTime: startTime,
      stopTime: stopTime,
      tokenAddress: tokenAddress
    });

    /* Increment the next stream id. */
    _nextStreamId++;

    emit CreateStream(
      streamId,
      address(this),
      recipient,
      deposit,
      tokenAddress,
      startTime,
      stopTime
    );
    return streamId;
  }

  /// @inheritdoc ICollector
  /**
   * @dev Throws if the id does not point to a valid stream.
   *  Throws if the caller is not the funds admin or the recipient of the stream.
   *  Throws if the amount exceeds the available balance.
   *  Throws if there is a token transfer failure.
   */
  function withdrawFromStream(
    uint256 streamId,
    uint256 amount
  ) external nonReentrant streamExists(streamId) onlyAdminOrRecipient(streamId) returns (bool) {
    require(amount > 0, 'amount is zero');
    Stream memory stream = _streams[streamId];

    uint256 balance = balanceOf(streamId, stream.recipient);
    require(balance >= amount, 'amount exceeds the available balance');

    _streams[streamId].remainingBalance = stream.remainingBalance - amount;

    if (_streams[streamId].remainingBalance == 0) delete _streams[streamId];

    IERC20(stream.tokenAddress).safeTransfer(stream.recipient, amount);
    emit WithdrawFromStream(streamId, stream.recipient, amount);
    return true;
  }

  /// @inheritdoc ICollector
  /**
   * @dev Throws if the id does not point to a valid stream.
   *  Throws if the caller is not the funds admin or the recipient of the stream.
   *  Throws if there is a token transfer failure.
   */
  function cancelStream(
    uint256 streamId
  ) external nonReentrant streamExists(streamId) onlyAdminOrRecipient(streamId) returns (bool) {
    Stream memory stream = _streams[streamId];
    uint256 senderBalance = balanceOf(streamId, stream.sender);
    uint256 recipientBalance = balanceOf(streamId, stream.recipient);

    delete _streams[streamId];

    IERC20 token = IERC20(stream.tokenAddress);
    if (recipientBalance > 0) token.safeTransfer(stream.recipient, recipientBalance);

    emit CancelStream(streamId, stream.sender, stream.recipient, senderBalance, recipientBalance);
    return true;
  }
}

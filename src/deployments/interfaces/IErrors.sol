// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IErrors {
  error L2MustBeEnabled();
  error L2MustBeDisabled();
  error ProviderNotFound();
  error InterestRateStrategyNotFound();
  error ProxyAdminNotFound();
  error PoolAdminNotFound();
}

# Running the certora verification tool

These instructions detail the process for running CVT on the contracts.

Documentation for CVT and the specification language are available
[here](https://certora.atlassian.net/wiki/spaces/CPD/overview)

## Running the verification

Initial step: if certora prover is not installed follow the steps [here](https://docs.certora.com/en/latest/docs/user-guide/getting-started/install.html)

First step is to create the munged/ directory. Enter the certora/ directory and run the following:

```sh
touch applyHarness.patch
```

```sh
make munged
```

The second and major step is to run all the verification rules.
The script `certora/scripts/run-all.sh` is used to submit all verification
jobs to the Certora verification service. These scripts should be run from the
root directory:

```sh
bash certora/scripts/run-all.sh
```

_Note: When running the rules locally, please remove the solc version from the `.conf` files as when using solc-select solc version should not be specified in `.conf`_

After the jobs are complete, the results will be available on
[the Certora portal](https://prover.certora.com/).

## Adapting to changes

Some of our rules require the code to be simplified in various ways. Our
primary tool for performing these simplifications is to run verification on a
contract that extends the original contracts and overrides some of the methods.
These "harness" contracts can be found in the `certora/harness` directory.

This pattern does require some modifications to the original code: some methods
need to be made virtual or public, for example. These changes are handled by
applying a patch to the code before verification.

When one of the `verify` scripts is executed, it first applies the patch file
`certora/applyHarness.patch` to the `contracts` directory, placing the output
in the `certora/munged` directory. We then verify the contracts in the
`certora/munged` directory.

If the original contracts change, it is possible to create a conflict with the
patch. In this case, the verify scripts will report an error message and output
rejected changes in the `munged` directory. After merging the changes, run
`make record` in the `certora` directory; this will regenerate the patch file,
which can then be checked into git.

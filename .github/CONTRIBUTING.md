# Contributing

Thanks for your interest in contributing to the Aave protocol! Please take a moment to review this document **before submitting a pull request.**

## Rules

1. Significant changes to the Protocol must be reviewed before a Pull Request is created. Create a [Feature Request](https://github.com/aave-dao/aave-v3-origin/issues) first to discuss your ideas.
2. Contributors must be humans, not bots.
3. First time contributions must not contain only spelling or grammatical fixes.

## Basic guide

This guide is intended to help you get started with contributing. By following these steps, you will understand the development process and workflow.

1. [Forking the repository](#forking-the-repository)
2. [Installing Foundry](#installing-foundry)
4. [Installing dependencies](#installing-dependencies)
5. [Running the test suite](#running-the-test-suite)
7. [Submitting a pull request](#submitting-a-pull-request)
8. [Versioning](#versioning)

---

### Forking the repository

To start contributing to the project, [fork it](https://github.com/aave-dao/aave-v3-origin/fork) to your private github account.

Once that is done, you can clone your forked repository to your local machine.
```bash
# https
git clone https://github.com/<user>/aave-v3-origin.git
# ssh
git clone git@github.com:<user>/aave-v3-origin.git
```

To stay up to date with the main repository, you can add it as a remote.
```bash
# https
git remote add upstream https://github.com/aave-dao/aave-v3-origin.git
# ssh
git remote add upstream git@github.com:aave-dao/aave-v3-origin.git
```

---

### Installing foundry

Aave-v3-origin is a [Foundry](https://github.com/foundry-rs/foundry) project.

Install foundry using the following command:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

---

### Installing dependencies

For generating the changelog, linting and testing, we rely on some additional node pckages. You can install them by running:

```bash
npm install
```

---

### Running the test suite

For running the default test suite you can use the following command:

```bash
forge test
```

In addition the the default test suite, you can run the [enigma fuzzing suite](./tests/invariants/README.md).

---

### Submitting a pull request

When you're ready to submit a pull request, you can follow these naming conventions:

- Pull request titles use the [Imperative Mood](https://en.wikipedia.org/wiki/Imperative_mood) (e.g., `Add something`, `Fix something`).
- [Changesets](#versioning) use past tense verbs (e.g., `Added something`, `Fixed something`).

When you submit a pull request, GitHub will automatically lint, build, and test your changes. If you see an ❌, it's most likely a bug in your code. Please, inspect the logs through the GitHub UI to find the cause.

- Pull requests must always cover all the changes made with tests. If you're adding a new feature, you must also add a test for it. If you're fixing a bug, you must add a test that reproduces the bug. Pull requests that cause a regression in test coverage will not be accepted.
- Pull requests that touch code functionality should always include updated gas snapshots. Running `forge test` will update the snapshots for you.
- Make sure that your updates are fitting within the existing code margin. You can check by running `forge build --sizes`

---

### Versioning

When adding new features or fixing bugs, we'll need to bump the package version. We use [Changesets](https://github.com/changesets/changesets) to do this.

Each changeset defines which package should be published and whether the change should be a minor/patch release, as well as providing release notes that will be added to the changelog upon release.

To create a new changeset, run `npm run changeset`. This will run the Changesets CLI, prompting you for details about the change. You’ll be able to edit the file after it’s created — don’t worry about getting everything perfect up front.

**Note**: As this repository is targeting `Aave V3` no major releases are allowed in this repository.

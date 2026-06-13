# Contributing to SarvMD

Thank you for your interest in contributing to **SarvMD**! We welcome and appreciate contributions from musicians, educators, and developers.

To ensure a smooth collaboration while protecting our intellectual property rights and keeping the project legally secure for commercial distribution, we have adopted a clear licensing, contributor model, and standard branching workflow. Please read this guide before contributing.

---

## 1. Project Licensing: Business Source License 1.1

All files and contributions to SarvMD are governed by the **Business Source License 1.1 (BUSL-1.1)**. 
*   **For Users**: The code is completely free for all non-commercial, personal, educational, and testing purposes. Commercial production use requires a separate license from the copyright owner (**Pooria Askari Moqaddam**).
*   **The Transition**: On **June, 2031**, this license automatically converts to the standard, permissive **Apache License 2.0**. From that date forward, all restrictions terminate.

By submitting a Pull Request, you agree that your contributions will be licensed under the **Business Source License 1.1**.

---

## 2. Contributor Policy: Developer Certificate of Origin (DCO)

We use the standard **Developer Certificate of Origin (DCO)** to manage copyright ownership of contributions. The DCO is a lightweight, industry-standard legal statement certifying that you have the right to submit the code you are contributing.

Rather than signing a complex, paper-based Contributor License Agreement (CLA), you simply **sign off** your git commits.

### The Developer Certificate of Origin (DCO) Text
By signing off a commit, you certify the following statements:

```text
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.

Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```

---

## 3. SarvMD Git Flow (Branching Strategy)

To ensure high-fidelity releases and maintain code stability, we follow standard **Git Flow** branching principles. 

```text
               [ hotfix/* ] (emergency patches)
                /        \
               /          v
   master <---+--------------------------+-----------> (stable / production releases)
     ^       /                          /
     |      / (tags)                   /
     |     /                          / (merge release)
     |    v                          v
   dev <---+-----------+---------+-----------------> (bleeding-edge / integration)
        ^   \         /         ^
         \   \       /         /
          \   v     /         / (merge feature)
           [ feature/* / bugfix/* ]
```

### 3.1 Persistent Branches
- **`master`**: Represents the most stable, production-ready state of SarvMD. Direct commits to `master` are strictly prohibited. Code only enters `master` via pull requests from a `release/*` branch or a `hotfix/*` branch. Every commit to `master` should be tagged with a semantic version (e.g., `v1.2.0`).
- **`dev`**: The primary integration branch. It contains all the bleeding-edge features and bugfixes intended for the next release. Direct commits to `dev` are prohibited. Code enters `dev` through PR reviews from active feature/bugfix branches.

### 3.2 Temporary Supporting Branches
- **Feature Branches (`feature/<name>` or `feat/<name>`)**:
  - Used to develop new features or major enhancements.
  - **Origin**: Branched from `dev`.
  - **Merge Target**: Merged back into `dev` via a Pull Request.
  - *Naming Example*: `feature/system-layout-drag-and-drop`, `feat/orientation-switcher`.
- **Bugfix Branches (`bugfix/<name>` or `fix/<name>`)**:
  - Used for standard bug fixes addressing issues on the `dev` branch.
  - **Origin**: Branched from `dev`.
  - **Merge Target**: Merged back into `dev` via a Pull Request.
  - *Naming Example*: `fix/ruler-precision-drift`, `bugfix/ensemble-builder-focus`.
- **Release Branches (`release/v<version>`)**:
  - Used to prepare, polish, and stabilize an upcoming release (runs final QA, updates version numbers, and modifies CHANGELOG).
  - **Origin**: Branched from `dev`.
  - **Merge Target**: Merged into `master` (and tagged) AND merged back into `dev` (to ensure any stabilization fixes are captured).
  - *Naming Example*: `release/v2.1.0`.
- **Hotfix Branches (`hotfix/<name>`)**:
  - Used for emergency production fixes that cannot wait for the standard development cycle.
  - **Origin**: Branched from `master`.
  - **Merge Target**: Merged into both `master` (and tagged) AND `dev`.
  - *Naming Example*: `hotfix/crash-on-file-save`.

---

## 4. Commit Quality Standards

 A clean, expressive, and uniform commit history makes debugging, code reviews, and automated changelog generation exceptionally simple.

### 4.1 Conventional Commits 1.0.0
We strictly enforce the Conventional Commits standard. Every commit must follow this format:

```text
<type>(<optional-scope>): <description>

[optional body]

[optional footer(s)]
```

#### Valid Commit Types
| Type | Purpose | Example |
| :--- | :--- | :--- |
| **`feat`** | A new feature or enhancement | `feat(ui): add visual layout switcher` |
| **`fix`** | A bug fix | `fix(core): resolve zero-rebuild focus loss` |
| **`docs`** | Documentation-only changes | `docs: translate README to Persian` |
| **`style`** | Code formatting, missing semi-colons, styling updates (no logic changes) | `style: run dart format on editor screen` |
| **`refactor`**| A code change that neither fixes a bug nor adds a feature | `refactor(layout): simplify system positioning engine` |
| **`perf`** | A code change that improves performance | `perf(preview): memoize Concentric CAD Target drawing` |
| **`test`** | Adding missing tests or correcting existing tests | `test(core): add unit tests for ensemble builder` |
| **`build`** | Changes that affect the build system or external dependencies | `build: upgrade dart sdk constraint to 3.6` |
| **`ci`** | Changes to CI configuration files and scripts | `ci: add github action for DCO checking` |
| **`chore`** | Other changes that don't modify src or test files | `chore: update gitignore` |
| **`revert`**| Reverts a previous commit | `revert: "feat: add orientation switcher"` |

#### Rules for the Description Line
1. **Imperative Mood**: Use the imperative, present tense ("add", "fix", "refactor") instead of past tense ("added", "fixed", "refactored").
2. **No Capitalization**: Start the description line with a lowercase letter.
3. **No Period**: Do not end the description line with a period.
4. **Length**: Limit the subject line to 72 characters or fewer.

---

## 5. How to Sign Off Your Commits (DCO compliance)

Signing off is extremely simple. It adds a line to your git commit message stating:

`Signed-off-by: Your Real Name <your.email@example.com>`

### For New Commits
When committing your changes, simply add the `-s` (or `--signoff`) flag to your git commit command:

```bash
git commit -s -m "feat(ui): implement precise music ruler updates"
```

Git will automatically append your signature using the name and email configured in your local git client (`git config user.name` and `git config user.email`).

### For Existing Commits (Amending)
If you created commits without the sign-off flag, you can easily amend the signature to your most recent commit:

```bash
git commit --amend --no-edit -s
```

If you have multiple commits in a branch that lack signatures, you can run an interactive rebase to sign them all off:

```bash
git rebase -i HEAD~N --signoff
```
*(Replace `N` with the number of commits in your branch).*

---

## 6. Commit Cleanup: Interactive Rebase & Linear History

Before opening a Pull Request or requesting review, contributors are expected to clean up their commit history. A history littered with "fixed typo", "refactor again", "oops", or "test fix" commits makes review difficult and pollutes the repository history.

### 6.1 Interactive Rebase Workflow
To clean up your commits, rebase your feature/bugfix branch interactively against the latest `dev` branch:

```bash
# 1. Fetch latest changes
git fetch origin

# 2. Rebase interactively
git rebase -i origin/dev
```

In the interactive text editor that opens:
*   Use **`pick`** for your primary, well-structured commits.
*   Use **`squash`** (or **`s`**) or **`fixup`** (or **`f`**) to combine micro-commits, polishing, and minor fixes into a single logical commit.
*   Use **`reword`** (or **`r`**) to fix commit messages to match Conventional Commit standards.

### 6.2 Force Pushing Safely
After rebasing, you will need to push to your remote branch. To do this safely without accidentally overwriting others' work:

```bash
git push --force-with-lease origin feature/your-feature-branch
```
> [!CAUTION]
> Never force push to persistent branches like `master` or `dev`. Force pushes are only permitted on your individual, temporary feature or bugfix branches.

---

## 7. Local Quality Gates (Pre-Submission Checklist)

To ensure the codebase remains clean, healthy, and bug-free, run the following local verification checks before committing and creating a Pull Request.

### 7.1 Automatic Code Formatting
All Dart and Flutter code must comply with standard Dart style rules. Run the formatter in the root of the workspace:

```bash
# Format all package and app source code in the workspace
dart format .
```

### 7.2 Static Code Analysis
Run the static analyzer to make sure there are zero lint issues, compiler warnings, or analysis errors:

```bash
# Run the analyzer over all packages in the workspace
dart analyze
```

### 7.3 Testing
Verify that all unit and widget tests run and pass perfectly:

```bash
# Run tests for core package
cd packages/sarvmd_core
dart test

# Run tests for UI application (using Flutter tool)
cd ../../apps/sarvmd_ui
flutter test
```

---

## 8. Pull Request & Review Lifecycle

1. **Open the PR**: Push your polished branch and open a Pull Request targeting the **`dev`** branch (except for `hotfix/*` branches, which target `master`).
2. **Fill out the Template**: Write a clear description detailing *what* changes were made and *why*.
3. **Automated Verification**: The CI/CD pipeline will automatically verify DCO Sign-off on all commits, run `dart format`, run `dart analyze`, and execute the test suites.
4. **Peer Review**: At least one maintainer or core contributor must review and approve the changes.
5. **Merge**: Once approved and all gates pass, the PR is merged into `dev` using a **Squash and Merge** or **Rebase and Merge** strategy to maintain a completely linear, beautiful commit history.

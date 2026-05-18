# Contributing to SarvMD

Thank you for your interest in contributing to **SarvMD**! We welcome and appreciate contributions from musicians, educators, and developers.

To ensure a smooth collaboration while protecting our intellectual property rights and keeping the project legally secure for commercial distribution, we have adopted a clear licensing and contributor model. Please read this guide before contributing.

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

## 3. How to Sign Off Your Commits

Signing off is extremely simple. It adds a line to your git commit message stating:

`Signed-off-by: Your Real Name <your.email@example.com>`

### For New Commits
When committing your changes, simply add the `-s` (or `--signoff`) flag to your git commit command:

```bash
git commit -s -m "feat: implement precise music ruler updates"
```

Git will automatically append your signature using the name and email configured in your local git client (`git config user.name` and `git config user.email`).

### For Existing Commits (Amending)
If you created commits without the sign-off flag, you can easily append the signature to your most recent commit:

```bash
git commit --amend --no-edit -s
```

If you have multiple commits in a branch that lack signatures, you can run an interactive rebase to sign them all off:

```bash
git rebase -i HEAD~N --signoff
```
*(Replace `N` with the number of commits in your pull request).*

---

## 4. Pull Request Requirements

To be merged, all Pull Requests must pass the following criteria:
1.  **DCO Verification**: Every single commit in the pull request history must contain a valid `Signed-off-by` line that matches the commit author's email. An automated GitHub Action will verify this.
2.  **Linting & Analysis**: Code must compile and pass all static analysis checks with zero errors. Run `dart analyze` before submitting.
3.  **Tests**: All unit and widget tests must pass cleanly.

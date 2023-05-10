## Legal

By submitting a pull request, you represent that you have the right to license
your contribution to Apple and the community, and agree by submitting the patch
that your contributions are licensed under the Apache 2.0 license (see
`LICENSE.txt`).

## How to submit a bug report

Please ensure to specify the following:

* Commit hash
* Contextual information (e.g. what you were trying to achieve with swift-openapi-generator)
* Simplest possible steps to reproduce
  * More complex the steps are, lower the priority will be.
  * A pull request with failing test case is preferred, but it's just fine to paste the test case into the issue description.
* Anything that might be relevant in your opinion, such as:
  * Swift version or the output of `swift --version`
  * OS version and the output of `uname -a`
  * Network configuration

### Example

```
Commit hash: b17a8a9f0f814c01a56977680cb68d8a779c951f

Context:
While testing my application that uses with swift-openapi-generator, I noticed that ...

Steps to reproduce:
1. ...
2. ...
3. ...
4. ...

$ swift --version
Swift version 4.0.2 (swift-4.0.2-RELEASE)
Target: x86_64-unknown-linux-gnu

Operating system: Ubuntu Linux 16.04 64-bit

$ uname -a
Linux beefy.machine 4.4.0-101-generic #124-Ubuntu SMP Fri Nov 10 18:29:59 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux

My system has IPv6 disabled.
```

## Writing a Patch

A good patch is:

1. Concise, and contains as few changes as needed to achieve the end result.
2. Tested, ensuring that any tests provided failed before the patch and pass after it.
3. Documented, adding API documentation as needed to cover new functions and properties.
4. Accompanied by a great commit message, using our commit message template.

### Run `./scripts/soundness.sh`

The scripts directory contains a [soundness.sh script](https://github.com/apple/swift-openapi-generator/blob/main/scripts/soundness.sh) 
that enforces additional checks, like license headers and formatting style.

Please make sure to `./scripts/soundness.sh` before pushing a change upstream, otherwise it is likely the PR validation will fail
on minor changes such as a missing `self.` or similar formatting issues.

For frequent contributors, we recommend adding the script as a [git pre-push hook](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks), which you can do via executing the following command in the project root directory: 

```bash
cat << EOF > .git/hooks/pre-push

if [[ -f "scripts/soundness.sh" ]]; then
  scripts/soundness.sh
fi
EOF
```

Which makes the script execute, and only allow the `git push` to complete if the check has passed.

In the case of formatting issues, you can then `git add` the formatting changes, and attempt the push again. 

## How to contribute your work

Please open a pull request at https://github.com/apple/swift-openapi-generator. Make sure the CI passes, and then wait for code review.

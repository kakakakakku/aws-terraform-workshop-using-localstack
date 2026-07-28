# Chapter 8: Run Static Analysis

With the `terraform fmt` command introduced in Chapter 7, you can standardize the format of your Terraform code to some extent.

However, when you use Terraform in a team and review Terraform code, it is also important to detect code that is (or could become) problematic, and to detect code that has (or could have) security concerns, beyond just formatting.

In Chapter 8, I introduce [TFLint](https://github.com/terraform-linters/tflint) and [Trivy](https://github.com/aquasecurity/trivy) as static analysis tools related to Terraform.

## TFLint

First is TFLint. TFLint is a linter for Terraform that can detect implementation mistakes, unnecessary settings, and more.

See the [TFLint repository](https://github.com/terraform-linters/tflint) for details.

Because it has a pluggable design, in addition to the **TFLint Ruleset for Terraform Language** built into TFLint by default, there is also the AWS-related **TFLint Ruleset for terraform-provider-aws**.

TFLint (the `tflint` command) is already set up in GitHub Codespaces.

```sh
$ tflint --version
TFLint version 0.55.1
+ ruleset.terraform (0.10.0-bundled)
```

Next, download the plugins with the `tflint --init` command. As I will explain later, the TFLint configuration file is `.tflint.hcl`.

```sh
$ cd ${CODESPACE_VSCODE_FOLDER}/chapter08
$ tflint --init
Installing "aws" plugin...
Installed "aws" (source: github.com/terraform-linters/tflint-ruleset-aws, version: 0.37.0)
```

### `main.tf`

Before running TFLint, let's look at `main.tf`. This code has three problems that TFLint can detect. Think about them for a moment before moving on.

```hcl
variable "retention_in_days" {
  type    = number
  default = 365
}

resource "aws_cloudwatch_log_group" "chapter08-test" {
  name              = "chapter08+logs"
  retention_in_days = 7
}
```

### The Result

Let's run the `tflint` command. When you run it, three problems are detected.

1. There is an unused `retention_in_days` variable
2. The resource naming convention is wrong (snake_case is recommended)
3. The Amazon CloudWatch log group name `chapter08+logs` contains an invalid `+`

As you can see, TFLint helps you improve your Terraform code 👌.

```sh
$ tflint
3 issue(s) found:

Warning: [Fixable] variable "retention_in_days" is declared but not used (terraform_unused_declarations)

  on main.tf line 1:
   1: variable "retention_in_days" {

Reference: https://github.com/terraform-linters/tflint-ruleset-terraform/blob/v0.10.0/docs/rules/terraform_unused_declarations.md

Notice: resource name `chapter08-test` must match the following format: snake_case (terraform_naming_convention)

  on main.tf line 6:
   6: resource "aws_cloudwatch_log_group" "chapter08-test" {

Reference: https://github.com/terraform-linters/tflint-ruleset-terraform/blob/v0.10.0/docs/rules/terraform_naming_convention.md

Error: "chapter08+logs" does not match valid pattern ^[\.\-_/#A-Za-z0-9]+$ (aws_cloudwatch_log_group_invalid_name)

  on main.tf line 7:
   7:   name              = "chapter08+logs"
```

The full list of **TFLint Ruleset for Terraform Language** rules is in the [rules documentation](https://github.com/terraform-linters/tflint-ruleset-terraform/tree/main/docs/rules).

The full list of **TFLint Ruleset for terraform-provider-aws** rules is also in the [rules documentation](https://github.com/terraform-linters/tflint-ruleset-aws/tree/master/docs/rules).

### `.tflint.hcl`

TFLint's settings are defined in `.tflint.hcl`. By default, TFLint includes the **Recommended** rules of the **TFLint Ruleset for Terraform Language**. The `terraform_naming_convention` rule, which detects errors in the resource naming convention (snake_case recommended), is not included in **recommended**, so we enable it individually in `.tflint.hcl`.

```hcl
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_naming_convention" {
  enabled = true
}

plugin "aws" {
    enabled = true
    version = "0.37.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
```

### Style Guide

By the way, the resource naming convention (snake_case recommended) is also covered in the Style Guide officially provided by Terraform. The Style Guide contains many other points worth keeping in mind, so it is worth reading through once 😀. See the [Terraform Style Guide](https://developer.hashicorp.com/terraform/language/style) for details.

## Trivy

Next is Trivy. Trivy is a security scanner that supports a wide range of targets, including OSes and programming languages. Of course, it supports Terraform too.

See the [Trivy repository](https://github.com/aquasecurity/trivy) for details.

Let's install Trivy.

```sh
$ curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.72.0
$ trivy --version
Version: 0.72.0
```

### The Result

Let's run the `trivy config` command.

When you run it, one problem is detected. The level is **LOW**! What was detected is that the Amazon CloudWatch log group is not encrypted with an AWS KMS customer-managed key. See the [AVD-AWS-0017 documentation](https://avd.aquasec.com/misconfig/aws/cloudwatch/avd-aws-0017/) for details.

Trivy's warnings are divided into levels — LOW / MEDIUM / HIGH / CRITICAL — so you do not necessarily have to address all of them. Discuss with your team and suppress the warnings you do not need, and operations will go more smoothly.

```sh
$ trivy config .

Report Summary

┌─────────┬───────────┬───────────────────┐
│ Target  │   Type    │ Misconfigurations │
├─────────┼───────────┼───────────────────┤
│ .       │ terraform │         0         │
├─────────┼───────────┼───────────────────┤
│ main.tf │ terraform │         1         │
└─────────┴───────────┴───────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


main.tf (terraform)

Tests: 1 (SUCCESSES: 0, FAILURES: 1)
Failures: 1 (UNKNOWN: 0, LOW: 1, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

AWS-0017 (LOW): Log group is not encrypted.
════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
CloudWatch log groups are encrypted by default, however, to get the full benefit of controlling key rotation and other KMS aspects a KMS CMK should be used.


See https://avd.aquasec.com/misconfig/aws-0017
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 main.tf:6-9
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   6 ┌ resource "aws_cloudwatch_log_group" "chapter08-test" {
   7 │   name              = "chapter08+logs"
   8 │   retention_in_days = 7
   9 └ }
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

```

The full list of AWS-related rules that Trivy can detect is in the [misconfiguration documentation](https://avd.aquasec.com/misconfig/aws/).

## GitHub Actions

This time, I introduced **TFLint** and **Trivy** by running them in a local environment.

Of course, running them while writing Terraform code is important, but running them with a Git Hook before committing, or running them automatically for each commit with GitHub Actions, is important too.

Especially in team development, you write Terraform code, open a pull request, and have it reviewed. Building a mechanism that detects problems automatically lets code reviews proceed efficiently.

To run TFLint and Trivy with GitHub Actions, you can easily define a GitHub Actions workflow using [terraform-linters/setup-tflint](https://github.com/terraform-linters/setup-tflint) and [aquasecurity/trivy-action](https://github.com/aquasecurity/trivy-action).

That's it for Chapter 8! ✋

## Code Walkthrough

Here is a quick walkthrough of the key points in the code. Feel free to skip this section.

### `provider.tf`

Same as Chapter 2.

### `main.tf`

Already explained above in Chapter 8.

That's it for the code walkthrough.

**Next: [Chapter 9: Learn the Basics of State Files](09-tfstate.md)**

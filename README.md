# DevSecOps pipeline lab with Docker Compose: Semgrep, Gitleaks, pip-audit, Trivy and a security gate

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-devsecops-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-devsecops-lab/actions/workflows/check.yml)

A ready-made lab for classrooms, from the [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning), where schools, colleges and universities give every student their own databases, containers and terminal in the browser. It teaches DevSecOps by building a security pipeline around a small web shop that has mistakes left in on purpose: static analysis with Semgrep, secret scanning of files and Git history with Gitleaks, dependency scanning with pip-audit, a dynamic baseline scan of the running shop, infrastructure as code scanning with Trivy, and a security gate that sets a commit status in Gitea so a protected branch refuses a merge until the gate passes. It is the lab behind the [DevSecOps pipelines](https://mitsurutech.co.uk/resources/university/devsecops-pipeline) module.

It is one `docker-compose` file, `compose.yaml`, and it runs the same on your own machine as it does on the platform, where every student gets a private copy. **Scan and attack only your own copy.** Scanning anybody else's site or code needs their written permission; in the UK, getting into a computer without permission is a crime under the Computer Misuse Act 1990.

## What is in it

| Service | What it is |
|---|---|
| `gitea` | Gitea, a Git server, holding `student/tuckshop` with four commits made at the first start. Account `student`, password `student`, both made up. Port 3000. |
| `shop` | The tuck shop, run straight from the repository: port 8000 as first written, port 8001 the same file run with `--hardened`. |
| `ci` | The pipeline's step runner, Python 3.12: `dast.py`, a small dynamic scanner written for this lab in the manner of OWASP ZAP's baseline scan, and `gate.py`, a security gate. pip-audit is installed here from PyPI when a lesson asks. |
| `semgrep` | Semgrep 1.185.0, offline, with the repository's own rules. |
| `gitleaks` | Gitleaks 8.30.1. It clones the repository into the shared volume `/work` at start, where every scanner reads it. |
| `trivy` | Trivy 0.76.2, for misconfigurations in the Dockerfile and Terraform, offline with the checks built into it. |

Every image is pinned by digest. **The shop's mistakes, its one account and the payments key in its Git history (`tuck_live_...`) are planted fixtures**, made up for the exercises: the key is the thing the secret scanning lesson finds, and none of it is a real credential. OWASP ZAP is not in the lab because its image is over a gigabyte of Java and needs more memory than a lab service is given, so `dast.py` stands in for its baseline scan and says so.

## Try it

From the terminal beside the lab, each tool runs with `docker exec`:

```bash
docker exec semgrep semgrep scan --config /work/tuckshop/.semgrep.yml --metrics=off /work/tuckshop
docker exec gitleaks gitleaks git /work/tuckshop --no-banner --redact -v
docker exec trivy trivy config -q /work/tuckshop
docker exec ci python3 dast.py http://shop:8000/ --active
docker exec ci python3 gate.py
```

The last one reads the JSON reports the scanners wrote into `/work/reports`, so run the scanners with their JSON options first, as the security gates lesson does with one pipeline file.

## Using it on the platform

The platform gives every student their own copy of a lab, in the browser, with a terminal beside it.

**To try it:** open the [container page](https://mitsurutech.co.uk/container), find this lab in **Sample labs** and press Start. It needs a free account.

**To set it as work for a class:**

1. In your module, make a task of type **Lab** and choose **In a GitHub repository**.
2. Give `https://github.com/mitsurutech/lab-devsecops-lab` with the branch `main`. The compose file is the default, `compose.yaml`. Fork the repository first if you want to change it.
3. Publish. Every student's copy starts from the commit you published, so a later change here does not alter a lab already set.

The help manual's [page for this lab](https://mitsurutech.co.uk/help/lab-devsecops-lab) and its [guide to container labs](https://mitsurutech.co.uk/help/labs) cover the rest. The matching basic lesson is **DevSecOps Basics**. No college account yet? [Your first year is free](https://mitsurutech.co.uk/pricing) for up to 50 students, and [signing up](https://mitsurutech.co.uk/signup) takes an email address.

## Running it on your own machine

You need Docker with the Compose plugin.

```bash
docker compose -f compose.yaml -f local.yaml up
```

Gitea answers on <http://127.0.0.1:3000> and the shop on <http://127.0.0.1:8000> and <http://127.0.0.1:8001>. `local.yaml` publishes the ports on `127.0.0.1` only. The shop is insecure on purpose, so do not run it where other people can reach it. Run the tools with `docker compose exec`, for example `docker compose exec semgrep semgrep --version`. Remove it all with `docker compose -f compose.yaml -f local.yaml down -v`.

## What does not work in a lab

On the platform a lab reaches only an allow-list of package sites: pip-audit comes from PyPI that way, and nothing else is downloaded. Semgrep cannot reach its rule registry, so it uses the repository's rules and the students' own, and Trivy uses its embedded checks. Gitea has no Actions runner, so students run the pipeline file themselves, as a runner would. The repository and `/work` are kept when the lab stops; the step runner's pip-audit is not.

## Checking the lab

`test/check.sh` starts the lab the way the platform's runner starts every service (all capabilities dropped, `no-new-privileges`, a process limit, a memory limit, and no way out to the internet except for the step runner's PyPI install) and then runs every command the lessons quote and checks what it prints, from a terminal with the tools the platform's terminal has. It needs Docker and runs on every push, which is the badge at the top.

```bash
test/check.sh
```

## Licence

This work is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). You may share it and adapt it for learning and teaching, if you credit Mitsuru Technologies Ltd, do not use it commercially, and share anything you make from it under the same licence. The full text is in the `LICENSE` file. Gitea, Semgrep, Gitleaks, Trivy and Python run unmodified from their own public images, each under its own licence.

## About

Made by [Mitsuru Technologies](https://mitsurutech.co.uk) for the [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning): Python, Java, Go, Node, SQL and Linux in the browser for schools and colleges, with container labs, web apps deployed from GitHub, and quizzes that mark themselves. Try code with no account in the [playground](https://mitsurutech.co.uk/playground).

More security labs from the same place: [lab-graphql-lab](https://github.com/mitsurutech/lab-graphql-lab), [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea).

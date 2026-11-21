#!/usr/bin/env bash
# What the lessons quote, checked from a terminal like the platform's (docker, git, curl, Python) on
# the lab's own network, one command at a time in one shell, as the lessons' Run buttons type them:
# run by check.sh. The services answer docker exec by their own names, as on the platform.
set -euo pipefail
: "${NET:?run through test/check.sh}"
docker run --rm -i --network "$NET" -v /var/run/docker.sock:/var/run/docker.sock -w /root lab-check-probe bash -s <<'IN'
set -eu
R=/work/tuckshop
G=http://gitea:3000/api/v1/repos/student/tuckshop
J='Content-Type: application/json'
plain() { sed 's/\x1b\[[0-9;]*m//g'; }
has() { # has <output> <text>...
  local out="$1"; shift
  for want in "$@"; do
    printf '%s' "$out" | grep -Fq -- "$want" || { echo "missing '$want' in: $out" >&2; exit 1; }
  done
}

echo "- nothing reaches the internet but the step runner"
if docker exec semgrep python3 -c "import urllib.request as u; u.urlopen('https://example.com', timeout=4)" 2>/dev/null; then echo "semgrep reached the internet" >&2; exit 1; fi

echo "- the repository: four commits, cloned into /work"
has "$(docker exec gitleaks git -C $R log --format=%s)" 'Describe the cloud it runs in' 'Read the payments key from the environment' 'Add card payments' 'Start the tuck shop'

echo "- lesson 1: Semgrep"
has "$(docker exec semgrep semgrep --version)" '1.185.0'
out=$(docker exec semgrep semgrep scan --config $R/.semgrep.yml --metrics=off $R 2>&1)
has "$out" '4 Code Findings' 'tuckshop.weak-password-hash' '32┆ return hashlib.md5' 'tuckshop.sql-built-from-strings' '41┆' '54┆' '58┆' 'Ran 3 rules on 2 files: 4 findings.'
docker exec -i semgrep sh -c 'cat > /work/rules/shell.yml' <<'EOF'
rules:
  - id: shell-with-input
    languages: [python]
    severity: ERROR
    message: A command built from a value and run through the shell.
    patterns:
      - pattern: subprocess.run($CMD, shell=True, ...)
      - pattern-not: subprocess.run("...", shell=True, ...)
EOF
out=$(docker exec semgrep semgrep scan --config /work/rules/shell.yml --metrics=off $R 2>&1)
has "$out" '1 Code Finding' 'rules.shell-with-input' '54┆'
if printf '%s' "$out" | grep -q '58┆'; then echo "the sharper rule still found line 58" >&2; exit 1; fi
docker exec semgrep semgrep scan --config $R/.semgrep.yml --metrics=off --config /work/rules --error --quiet --json-output=/work/reports/semgrep.json $R > /dev/null && { echo "--error did not fail" >&2; exit 1; } || true
has "$(docker exec semgrep grep -n like $R/app.py)" '40:' 'like ?' '41:'

echo "- lesson 2: Gitleaks"
has "$(docker exec gitleaks gitleaks version)" 'v8.30.1'
has "$(docker exec gitleaks gitleaks dir $R --no-banner --redact 2>&1 | plain)" 'no leaks found'
out=$(docker exec gitleaks gitleaks git $R --no-banner --redact -v 2>&1 | plain || true)
has "$out" 'RuleID:      generic-api-key' 'Entropy:     4.910992' 'File:        settings.py' 'Date:        2026-01-12T10:30:00Z' '4 commits scanned' 'leaks found: 1'
docker exec -i gitleaks sh -c 'cat > /work/rules/gitleaks.toml' <<'EOF'
[extend]
useDefault = true

[[rules]]
id = "tuckshop-payments-key"
description = "Tuck shop payments key"
regex = '''tuck_live_[A-Za-z0-9]{24}'''
keywords = ["tuck_live_"]
EOF
has "$(docker exec gitleaks gitleaks git $R --config /work/rules/gitleaks.toml --no-banner --redact -v 2>&1 | plain || true)" 'RuleID:      tuckshop-payments-key' 'leaks found: 1'
docker exec gitleaks sh -c "gitleaks git $R --no-banner -v 2>/dev/null | grep Fingerprint | cut -d' ' -f2 > /work/rules/.gitleaksignore"
has "$(docker exec gitleaks gitleaks git $R --gitleaks-ignore-path /work/rules/.gitleaksignore --no-banner 2>&1 | plain)" 'no leaks found'
git clone -q http://student:student@gitea:3000/student/tuckshop.git
printf '#!/bin/sh\ngit diff --cached | docker exec -i gitleaks gitleaks stdin --no-banner --redact\n' > tuckshop/.git/hooks/pre-commit && chmod +x tuckshop/.git/hooks/pre-commit
echo 'PAYMENTS_KEY = "tuck_live_Zz9Yy8Xx7Ww6Vv5Uu4Tt3Ss2"' >> tuckshop/settings.py
if git -C tuckshop -c user.name=Student -c user.email=student@example.com commit -qam 'Try a key' 2>/dev/null; then echo "the hook let a key through" >&2; exit 1; fi
[ "$(git -C tuckshop log --oneline | wc -l)" = 4 ] || { echo "a commit was made" >&2; exit 1; }
git -C tuckshop checkout -q settings.py

echo "- lesson 3: pip-audit, from PyPI"
docker exec ci pip install -q --user --no-warn-script-location pip-audit==2.10.1
out=$(docker exec ci python3 -m pip_audit -r $R/requirements.txt --no-deps --disable-pip 2>&1 || true)
has "$out" 'known vulnerabilities in 3 packages' 'PYSEC-2018-28   2.20.0' 'PYSEC-2020-96   5.3.1' 'PYSEC-2021-142  5.4' 'PYSEC-2019-217  2.10.1'
docker exec ci sh -c "printf 'requests==2.33.0\nPyYAML==6.0.2\nJinja2==3.1.6\n' > /work/reports/requirements-new.txt"
echo "  bumped: $(docker exec ci python3 -m pip_audit -r /work/reports/requirements-new.txt --no-deps --disable-pip 2>&1 | tail -1)"

echo "- lesson 4: the baseline scanner, weak and hardened"
has "$(curl -s -D - -o /dev/null http://shop:8000/)" 'Server: TuckShop/0.9 Python/3.12' 'Set-Cookie: cart=' '; Path=/'
has "$(docker exec ci python3 dast.py http://shop:8000/)" 'Scanned 7 pages' 'Error page shows a stack trace [7] Medium x 1' 'FAIL: 0  WARN: 7  IGNORE: 0  PASS: 0'
has "$(docker exec ci python3 dast.py http://shop:8000/ --active)" 'Input reflected without escaping (active) [8] High x 1' 'FAIL: 0  WARN: 8'
has "$(docker exec ci python3 dast.py http://shop:8001/ --active)" 'FAIL: 0  WARN: 0  IGNORE: 0  PASS: 8'
has "$(curl -s -D - -o /dev/null http://shop:8001/)" 'HttpOnly; Secure; SameSite=Lax' 'X-Frame-Options: DENY' 'X-Content-Type-Options: nosniff'
printf '1 FAIL every page needs a policy\n4 IGNORE the proxy in front removes the header\n7 FAIL never show a stack trace\n' | docker exec -i ci sh -c 'cat > /work/rules/dast.conf'
out=$(docker exec ci python3 dast.py http://shop:8000/ --config /work/rules/dast.conf --json /work/reports/dast.json || echo "exit $?")
has "$out" 'FAIL: 2  WARN: 4  IGNORE: 1  PASS: 0' 'exit 1'

echo "- lesson 5: Trivy, offline"
out=$(docker exec trivy trivy config -q $R/Dockerfile)
has "$out" 'Tests: 27 (SUCCESSES: 23, FAILURES: 4)' 'DS-0001 (MEDIUM)' 'DS-0002 (HIGH)' 'DS-0005 (LOW)' 'DS-0026 (LOW)'
out=$(docker exec trivy trivy config -q --severity HIGH,CRITICAL $R/deploy)
has "$out" 'Tests: 7 (SUCCESSES: 0, FAILURES: 7)' 'AWS-0092 (HIGH): Bucket has a public ACL: "public-read"' 'AWS-0107 (HIGH)'
printf 'FROM python:3.12.15-alpine\nWORKDIR /app\nCOPY . /app\nRUN pip install --no-cache-dir -r requirements.txt\nUSER 65532\nHEALTHCHECK CMD python3 -c "import urllib.request as u; u.urlopen(\x27http://127.0.0.1:8000/health\x27)"\nEXPOSE 8000\nCMD ["python3", "app.py"]\n' \
  | docker exec -i trivy sh -c 'mkdir -p /work/fixed && cat > /work/fixed/Dockerfile'
has "$(docker exec trivy trivy config -q /work/fixed)" '│ Dockerfile │ dockerfile │         0         │'

echo "- lesson 6: the gate, a protected branch and a merge"
docker exec semgrep semgrep scan --config $R/.semgrep.yml --metrics=off --quiet --json-output=/work/reports/semgrep.json $R > /dev/null || true
docker exec gitleaks gitleaks git $R --no-banner --redact --report-format json --report-path /work/reports/gitleaks.json 2> /dev/null || true
docker exec ci python3 -m pip_audit -r $R/requirements.txt --no-deps --disable-pip -f json -o /work/reports/audit.json 2> /dev/null || true
docker exec trivy trivy config -q -f json -o /work/reports/trivy.json $R
docker exec ci python3 dast.py http://shop:8000/ --json /work/reports/dast.json > /dev/null
has "$(docker exec ci python3 gate.py || true)" 'gitleaks   1 findings (1 critical)' 'semgrep    3 findings (2 high, 1 medium)' 'trivy      15 findings (8 high, 2 medium, 5 low)' 'Gate: FAIL'
[ "$(curl -s -o /dev/null -w '%{http_code}' -u student:student -H "$J" -d '{"rule_name":"main","enable_status_check":true,"status_check_contexts":["security-gate"]}' $G/branch_protections)" = 201 ]
has "$(docker exec ci python3 gate.py --post main || true)" 'Status failure set on main'
git -C tuckshop switch -q -c gate-policy
RULE=generic-api-key
printf '{\n  "fail_at": "critical",\n  "baseline": [\n    {"key": "gitleaks:'"$RULE"':settings.py", "reason": "Rotated on 13 January 2026, old key revoked", "expires": "2030-06-30"},\n    {"key": "semgrep:weak-password-hash:app.py", "reason": "", "expires": "2026-01-31"}\n  ]\n}\n' > tuckshop/security-policy.json
git -C tuckshop add security-policy.json && git -C tuckshop -c user.name=Student -c user.email=student@example.com commit -qm "Add the security policy" && git -C tuckshop push -q -u origin gate-policy 2>/dev/null
has "$(curl -s -u student:student -H "$J" -d '{"head":"gate-policy","base":"main","title":"Add the security policy"}' $G/pulls | grep -o '"number":[0-9]*' | head -1)" '"number":1'
has "$(curl -s -u student:student -H "$J" -d '{"Do":"merge"}' $G/pulls/1/merge)" 'Not all required status checks successful'
docker exec gitleaks sh -c "cd $R && git fetch -q origin && git checkout -q gate-policy"
out=$(docker exec ci python3 gate.py --post gate-policy)
has "$out" 'Baseline entry ignored (no reason, or past its date): semgrep:weak-password-hash:app.py' 'Blocking, at or above critical and not accepted: 0' 'Gate: PASS' 'Status success set on gate-policy'
[ "$(curl -s -o /dev/null -w '%{http_code}' -u student:student -H "$J" -d '{"Do":"merge"}' $G/pulls/1/merge)" = 200 ]
echo "all quoted lines hold"
IN

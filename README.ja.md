# Docker Composeで学ぶDevSecOpsパイプラインのラボ：Semgrep、Gitleaks、pip-audit、Trivyとセキュリティゲート

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-devsecops-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-devsecops-lab/actions/workflows/check.yml)

[MitsuruTechラーニングプラットフォーム](https://mitsurutech.co.uk/ja/learning)の、授業ですぐ使えるラボです。このプラットフォームでは、学校や大学が学生一人ひとりに自分のデータベース、コンテナ、ターミナルをブラウザで用意できます。このラボでは、わざと誤りを残した小さなWebショップのまわりにセキュリティパイプラインを組み立てながら、DevSecOpsを学びます。Semgrepによる静的解析、GitleaksによるファイルとGit履歴のシークレット検出、pip-auditによる依存関係のスキャン、動いているショップへの動的なベースラインスキャン、TrivyによるInfrastructure as Codeのスキャン、そしてGiteaにコミットステータスを設定し、ゲートを通るまで保護ブランチがマージを拒むようにするセキュリティゲートです。[DevSecOps pipelines](https://mitsurutech.co.uk/resources/university/devsecops-pipeline)モジュールのためのラボです。

`docker-compose`ファイル1つ、`compose.yaml`だけでできていて、自分のマシンでもプラットフォームでも同じように動きます。プラットフォームでは、学生一人ひとりが自分専用のコピーを使います。**スキャンも攻撃も、自分のコピーにだけ行ってください。** ほかの人のサイトやコードをスキャンするには、その人の書面による許可が必要です。英国では、許可なくコンピューターに侵入することはComputer Misuse Act 1990に基づく犯罪です。

## 中身

| サービス | 内容 |
|---|---|
| `gitea` | GitサーバーのGiteaです。`student/tuckshop`を持ち、初回起動時に4つのコミットが作られます。アカウントは`student`、パスワードは`student`で、どちらも架空のものです。ポートは3000です。 |
| `shop` | 学校の売店のショップで、リポジトリから直接動かします。ポート8000は最初に書かれたままのもの、ポート8001は同じファイルを`--hardened`つきで動かしたものです。 |
| `ci` | パイプラインのステップを実行するPython 3.12です。OWASP ZAPのベースラインスキャンにならってこのラボのために書いた小さな動的スキャナー`dast.py`と、セキュリティゲートの`gate.py`があります。レッスンで必要になると、pip-auditをここにPyPIからインストールします。 |
| `semgrep` | Semgrep 1.185.0です。オフラインで、リポジトリ自身のルールを使います。 |
| `gitleaks` | Gitleaks 8.30.1です。起動時にリポジトリを共有ボリューム`/work`にクローンし、各スキャナーはそこから読みます。 |
| `trivy` | Trivy 0.76.2です。DockerfileとTerraformの設定ミスを、組み込みのチェックを使ってオフラインで調べます。 |

どのイメージもダイジェストで固定しています。**ショップの誤り、ただ1つのアカウント、Git履歴にある決済キー（`tuck_live_...`）は、演習用に仕込んだフィクスチャ**で、演習のために作ったものです。このキーこそがシークレット検出のレッスンで見つけるもので、どれも本物の認証情報ではありません。OWASP ZAPはラボに入れていません。そのイメージは1ギガバイトを超えるJavaで、ラボのサービスに割り当てるより多くのメモリが必要だからです。そのため`dast.py`がベースラインスキャンの代わりを務め、そのことを明示しています。

## 試してみる

ラボの横のターミナルから、各ツールを`docker exec`で動かします。

```bash
docker exec semgrep semgrep scan --config /work/tuckshop/.semgrep.yml --metrics=off /work/tuckshop
docker exec gitleaks gitleaks git /work/tuckshop --no-banner --redact -v
docker exec trivy trivy config -q /work/tuckshop
docker exec ci python3 dast.py http://shop:8000/ --active
docker exec ci python3 gate.py
```

最後のコマンドは、スキャナーが`/work/reports`に書いたJSONレポートを読みます。セキュリティゲートのレッスンが1つのパイプラインファイルで行うように、先にスキャナーをJSONのオプションつきで実行してください。

## プラットフォームでの使い方

プラットフォームは、すべての学生にラボの専用コピーをブラウザで提供し、横にターミナルを用意します。

**試すには：**[コンテナのページ](https://mitsurutech.co.uk/ja/container)を開き、**Sample labs**でこのラボを探してStartを押します。無料アカウントが必要です。

**クラスの課題にするには：**

1. モジュールで種類が**Lab**のタスクを作り、**In a GitHub repository**を選びます。
2. `https://github.com/mitsurutech/lab-devsecops-lab`とブランチ`main`を指定します。composeファイルは既定の`compose.yaml`です。変更したい場合は、先にリポジトリをフォークしてください。
3. 公開します。学生のコピーは公開したコミットから始まるので、あとでここが変わっても、すでに出したラボは変わりません。

ヘルプマニュアルの[このラボのページ](https://mitsurutech.co.uk/help/lab-devsecops-lab)と[コンテナラボのガイド](https://mitsurutech.co.uk/ja/help/labs)に、ほかのことが書いてあります。対応する基本レッスンは**DevSecOps Basics**です。まだ学校のアカウントがありませんか。生徒50人までなら[最初の1年は無料](https://mitsurutech.co.uk/ja/pricing)で、[登録](https://mitsurutech.co.uk/ja/signup)に必要なのはメールアドレスだけです。

## 自分のマシンで動かす

Composeプラグインつきのdockerが必要です。

```bash
docker compose -f compose.yaml -f local.yaml up
```

Giteaは<http://127.0.0.1:3000>、ショップは<http://127.0.0.1:8000>と<http://127.0.0.1:8001>で応答します。`local.yaml`はポートを`127.0.0.1`にだけ公開します。ショップはわざと安全でなく作ってあるので、ほかの人が届く場所では動かさないでください。ツールは`docker compose exec`で動かします。たとえば`docker compose exec semgrep semgrep --version`です。すべて削除するには`docker compose -f compose.yaml -f local.yaml down -v`を実行します。

## ラボでできないこと

プラットフォームでは、ラボが届くのは許可リストにあるパッケージサイトだけです。pip-auditはその経路でPyPIから取得し、それ以外は何もダウンロードしません。Semgrepはルールのレジストリに届かないので、リポジトリのルールと学生自身のルールを使い、Trivyは組み込みのチェックを使います。GiteaにはActionsのランナーがないので、学生がランナーの代わりにパイプラインファイルを自分で実行します。リポジトリと`/work`はラボを止めても残りますが、ステップ実行用コンテナのpip-auditは残りません。

## ラボの確認

`test/check.sh`は、プラットフォームのランナーがすべてのサービスを起動するのと同じやり方（ケーパビリティをすべて外し、`no-new-privileges`、プロセス数の上限、メモリの上限、ステップ実行用コンテナのPyPIからのインストールを除いてインターネットへの経路なし）でラボを起動し、プラットフォームのターミナルと同じツールを持つターミナルから、レッスンに出てくるコマンドをすべて実行して、出力を確かめます。Dockerが必要で、pushのたびに実行されます。それが上のバッジです。

```bash
test/check.sh
```

## ライセンス

この作品は[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.ja)でライセンスされています。Mitsuru Technologies Ltdのクレジットを表示し、営利目的で使わず、作ったものを同じライセンスで共有するなら、学習と教育のために共有したり改変したりできます。全文は`LICENSE`ファイルにあります。Gitea、Semgrep、Gitleaks、Trivy、Pythonは、それぞれの公開イメージから変更せずに動かしており、それぞれのライセンスに従います。

## このラボについて

[Mitsuru Technologies](https://mitsurutech.co.uk/ja)が[MitsuruTechラーニングプラットフォーム](https://mitsurutech.co.uk/ja/learning)のために作りました。学校向けに、Python、Java、Go、Node、SQL、Linuxをブラウザで使え、コンテナラボ、GitHubからデプロイするWebアプリ、自動採点のクイズがあります。アカウントなしでも[プレイグラウンド](https://mitsurutech.co.uk/ja/playground)でコードを試せます。

同じところのほかのセキュリティラボ：[lab-graphql-lab](https://github.com/mitsurutech/lab-graphql-lab)、[lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea)。

# Codex Agents ガードレールガイド

このリポジトリには、Codex エージェントに対して安全な作業手順を与えるためのガードレールテンプレートが含まれています。以下の手順に従って、自分の環境に合わせたポリシーを用意してください。

## ガードレールテンプレートのコピー

- `guardrails/guardrails.yaml` に標準的なガードレール定義を用意しています。
- テンプレートを編集可能な場所にコピーし、コメントを削除または調整してポリシーの最終形に仕上げてください。

```bash
cp guardrails/guardrails.yaml guardrails/guardrails.yaml
```

## 主なポリシー内容

- **危険なシェルコマンドの遮断**: `rm -rf /` や `mkfs` など破壊的なコマンドを拒否します。
- **Git 履歴の保護**: `git push --force` や `git reset --hard` などの履歴改変をブロックします。
- **ファイル編集の制限**: `apply_patch` の適用範囲を `/workspace` 以下に制限し、バイナリファイル編集を禁止します。
- **パッケージ操作の確認**: `apt install` や `npm install` などシステムに影響するコマンドは確認プロンプトを求めます。
- **ホワイトリスト**: `ls` や `git status` など日常的な安全コマンドは即許可します。

## Codex CLI への組み込み

Codex CLI のバージョンによって、ガードレールの読み込み方法が異なる場合があります。代表的な設定例を挙げます。

- CLI のオプションでファイルを指定する: `codex chat --guardrails guardrails/guardrails.yaml`
- 環境変数で指定する: `export CODEX_GUARDRAILS_FILE=$(pwd)/guardrails/guardrails.yaml`
- 自動化スクリプトに組み込む場合も、ガードレールファイルへのパスを明示的に渡すようにしてください。

## カスタマイズのヒント

- **チーム独自の禁止パターン**があれば、正規表現ルールを追加して対応します。
- **環境固有のパス**やボリューム名は `rules` や `allowlist` の正規表現を更新して整合性を持たせてください。
- ポリシーの変更点はコードレビューを通し、破壊的なコマンドが通っていないかを確認することを推奨します。

## 運用上のベストプラクティス

- ガードレールは「できるだけ安全に自動化を進めるための補助」と捉え、人間によるレビューや承認フローと組み合わせて運用します。
- テンプレートを更新した場合は、変更履歴を追いやすくするために Pull Request またはチャットでチームに共有します。
- 定期的にログや実行履歴を確認し、誤検知や未検知のパターンが無いか見直してください。

# Agent Policy: Plan → Approve → Execute

## Execution Policy
- DEFAULT_AUTO_APPROVE: true   <!-- ここで自動承認の既定を宣言 -->
- Plan は JSON のみを出力し、実行はしない。
- Plan JSON は必ず `meta.auto_approve` を含め、ここには `DEFAULT_AUTO_APPROVE` を反映する。
- `meta.auto_approve` が true でも、**サーバ側の Guardrail に違反する手順は実行不可**。
- 破壊的操作・ネットワーク操作は必ず `risk:"high"` と分類する。

## Plan JSON 形式
```json
{
  "plan_id": "xxxx",
  "ttl_minutes": 30,
  "working_dir": "/home/agent/work",
  "meta": { "auto_approve": true },
  "steps": [
    { "id":"1","cmd":"ls -la","cwd":"/home/agent/work","rationale":"確認","risk":"low" }
  ]
}


##  Subshell Prohibition（サブシェル禁止ルール）

### 禁止対象
- `bash -c`
- `sh -c`
- `eval`
- バッククォート（ `` `...` `` ）

### 禁止理由
- ガードレールやログ監査を回避できてしまう。  
- 文字列再解釈により、意図しない破壊的コマンドを実行するリスクがある。  
- Codex エージェントによる `bash -c "..."` の乱用は安全性を大きく下げる。  

### 運用ルール
- これらの構文を**生成・実行してはならない**。  
- 複数コマンドを組み合わせたい場合は **Plan の steps を分割** する。  
- コマンド提案は **argv形式**（例：`["git", "status"]`）で提示すること。  
- これに違反する Plan は Guardrail により自動ブロックされる。  

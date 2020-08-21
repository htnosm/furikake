# 変更点

## 検索対象リソース追加

| resource | content |
| :--- | :--- |
| health | AWS Health イベント |
| health_regional | AWS Health イベント(リージョン固有) |
| route53 | Route53 レコードセット |

## その他

* 読込失敗時のエラー出力追加
* Markdown Table出力時の先頭・末尾の区切り文字追加
    * markdown-tables の VerUp

* yml設定でのリソース順を保持して出力
    * .furikake.yml で `keep_config_order: true` 指定

```yaml
resources:
  keep_config_order: true
  aws:
    - ...
```

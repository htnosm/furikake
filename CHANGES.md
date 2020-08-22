# 変更点

## 検索対象リソース追加

| resource | content |
| :--- | :--- |
| ebs | EBS |
| ec2_with_vol | EC2 に Volume 情報付与 |
| health | AWS Health イベント |
| health_regional | AWS Health イベント(リージョン固有) |
| route53 | Route53 レコードセット |
| s3 | S3バケット |
| s3_regional | S3バケット(リージョン固有) |

## その他

* 読込失敗時のエラー出力追加
* Markdown Table出力時の先頭・末尾の区切り文字追加
    * markdown-tables の VerUp
* 出力順序固定(Nameでのsort)

* yml設定でのリソース順を保持して出力
    * .furikake.yml で `keep_config_order: true` 指定

```yaml
resources:
  keep_config_order: true
  aws:
    - ...
```

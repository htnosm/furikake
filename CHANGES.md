# 変更点

## 検索対象リソース追加

| resource | content |
| :--- | :--- |
| acm | AWS Certificate Manager |
| auto_scaling | Auto Scaling Group |
| cloudfront | CloudFront Distribution |
| ebs | EBS |
| ec2_with_vol | EC2 に Volume 情報付与 |
| health | AWS Health イベント |
| health_regional | AWS Health イベント(リージョン固有) |
| route_table | VPC Route Table |
| route53 | Route53 レコードセット |
| s3 | S3バケット |
| s3_regional | S3バケット(リージョン固有) |

## その他

* 読込失敗時のエラー出力追加
* 各リソース出力の順序固定(Nameでのsort)

### Markdown Table出力

* 先頭・末尾の区切り文字追加
    * markdown-tables の VerUp
* セパレータを1文字から3文字へ
* Backlog上でのテーブル形式崩れの対応

### 設定ファイルの順序保持

* yml設定でのリソース順を保持して出力
    * .furikake.yml で `keep_config_order: true` 指定

```yaml
resources:
  keep_config_order: true
  aws:
    - ...
```

### Wiki作成

* wiki_id 指定がない場合のWikiページ作成処理
* .furikake.yml で `project_key: xxx`、 `wiki_name: xxx` を指定
    * wiki_id 指定がある場合は project_key は無視
    * 作成後は指定BacklogプロジェクトのWikiを wiki_name で検索し、 wiki_id 取得 (wiki_id指定不要)

```yaml
backlog:
  projects:
    - space_id: 'x-tech5'
      #wiki_id: your-wiki-id # 指定した場合は wiki_id 優先
      wiki_name: 'your-wiki-name'
      project_key: 'XXXXX' # Backlog ProjectKey
```

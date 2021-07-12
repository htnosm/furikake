# 変更点

## 検索対象リソース追加

| resource | content |
| :--- | :--- |
| alb_with_target_health | ALB/NLB に Target(Instance) 情報付与 |
| acm | AWS Certificate Manager |
| auto_scaling | Auto Scaling Group |
| cloudfront | CloudFront Distribution |
| ebs | EBS |
| ec2_with_vol | EC2 に Volume 情報付与 |
| health | AWS Health イベント(オープン) |
| health_regional | AWS Health イベント(オープン、リージョン固有) |
| iam_role | IAM Role |
| iam_role_exclude_service_role | IAM Role(パスが "/aws-service-role/、/service-role/" 以外)
| iam_group | IAM Group |
| iam_user | IAM User |
| redshift | Redshift |
| route_table | VPC Route Table |
| route53 | Route53 レコードセット |
| route53_domains | Route53 ドメイン |
| s3 | S3バケット |
| s3_regional | S3バケット(リージョン固有) |
| vpc_peering | VPC Peering |
| vpc_subnet | VPC Subnet |
| wafv2 | AWS WAF(V2) |

## その他

* 読込失敗時のエラー出力追加
* 各リソース出力の順序固定(Nameでのsort)
* vpc_endpoint Tag:Name の修正
* SecurityGroup列追加
  * ec2,alb,clb,rds,redshift
* ParameterGroup列追加
  * rds,redshift
* clb へ listener セクション追加

### Markdown Table出力

* 先頭・末尾の区切り文字追加
    * markdown-tables の VerUp
* セパレータを1文字から3文字へ
* Backlog上でのテーブル形式崩れの対応

### 設定ファイルの順序保持

* yml設定でのリソース順を保持して出力
    * .furikake.yml で `keep_config_order: true` 指定
* 取得対象のタグを指定(filtersでのtag指定に対応しているリソースのみ)
    * .furikake.yml で `filters: []` 指定
    * filters 対応リソースへの共通設定
    * 末尾に備考として "抽出条件" を出力
* 出力タグキーを指定(対応しているリソースのみ)
    * .furikake.yml で `output_tag_keys: []` 指定
    * 末尾に備考として "Tags列への出力タグキー" を出力

```yaml
options:
  keep_config_order: true
  filters:
    # tag キーと値での絞り込み例
    - name: "tag:env"
      values: ["dev", "stg"]
    # tag キーのみでの絞り込み例
    - name: "tag-key"
      values: ["aws:cloudformation:stack-id", "aws:cloudformation:stack-name"]
  output_tag_keys:
    - "Name"
    - "aws:autoscaling:groupName"
```

### Wiki作成(ProjectKey指定)

* wiki_id 指定がない場合のWikiページ作成処理
* .furikake.yml で `project_key: xxx`、 `wiki_name: xxx` を指定
    * wiki_id 指定がある場合は project_key は無視
    * 作成後は指定BacklogプロジェクトのWikiを wiki_name で検索し、 wiki_id 取得 (wiki_id指定不要)

```yaml
backlog:
  projects:
    - space_id: 'your-space-id'
      #wiki_id: your-wiki-id # 指定した場合は wiki_id 優先
      wiki_name: 'your-wiki-name'
      project_key: 'XXXXX' # Backlog ProjectKey
```

### 差分出力

* 取得リソース情報とWikiの差分出力

```
Usage:
  furikake diff

resouces diffs print.
```

* publishへオプション追加
  * `--force false` 指定で差分が無い場合の更新を抑止

```
Usage:
  furikake publish

Options:
  -f, [--force]  # force publish.
                 # Default: true

resouces publish to something. (Default: Backlog)
```

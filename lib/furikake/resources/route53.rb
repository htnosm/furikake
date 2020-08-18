# encoding: utf-8

module Furikake
  module Resources
    module Route53
      def report

        documents = <<"EOS"
### Route53
EOS
        headers = [
          'RecordName',
          'Type',
          'TTL',
          'Values',
        ]

        get_resources.each do |resources|
          info = MarkdownTables.make_table(headers, resources.last, is_rows: true, align: 'l')
          document = <<"EOS"

#### #{resources[1]} (#{resources[0]})

#{info}
EOS
          documents << document
        end

        # Backlog上でのテーブル形式崩れの対応
        ## アンダースコア (|_) へバックスラッシュ挿入
        documents.gsub!(/\|_/, "|\\_")
        ## 空白 (||) へスペース挿入
        documents.gsub!(/\|\|/, "| |").gsub!(/\|\|/, "| |")

        documents
      end

      def get_resources
        route53 = Aws::Route53::Client.new
        params = {}
        hosted_zones = []
        loop do
          res = route53.list_hosted_zones(params)
          res.hosted_zones.each do |h|
            hosted_zone = []
            hosted_zone_id = h.id
            hosted_zone_id = hosted_zone_id.gsub!("/hostedzone/", "")
            hosted_zone << hosted_zone_id
            hosted_zone << h.name

            rs_params = {
              hosted_zone_id: hosted_zone_id
            }
            record_sets = []
            loop do
              rs_res = route53.list_resource_record_sets(rs_params)
              rs_res.resource_record_sets.each do |r|
                record_set = []
                record_set << r.name
                record_set << r.type
                record_set << r.ttl

                resource_records = []
                r.resource_records.each do |rr|
                  resource_records << rr.value
                end
                if resource_records.length > 0
                  record_set << resource_records.join(",")
                else
                  if not (r.alias_target.nil? || r.alias_target.empty?)
                    record_set << r.alias_target.dns_name
                  end
                end

                record_sets << record_set
              end

              break unless rs_res.is_truncated
              params[:start_record_name] = rs_res.next_record_name
              params[:start_record_type] = rs_res.next_record_type
            end

            hosted_zone << record_sets
            hosted_zones << hosted_zone
          end

          break unless res.is_truncated
          params[:next_token] = res.next_token
        end
        hosted_zones
      end

      module_function :report, :get_resources
    end
  end
end

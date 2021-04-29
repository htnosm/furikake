require "json"

module Furikake
  module Resources
    module Wafv2
      def report
        web_acls, rules, resources, ip_sets = get_resources

        headers = ['Scope', 'WAF ACL Name', 'ID', 'Description']
        if web_acls.empty?
          web_acl_info = 'N/A'
        else
          web_acl_info = MarkdownTables.make_table(headers,
                                                   web_acls,
                                                   is_rows: true,
                                                   align: 'l')
        end

        headers = ['WAF ACL Name', 'ID', 'Rule Name', 'Priority', 'Statement']
        if rules.empty?
          rule_info = 'N/A'
        else
          rule_info = MarkdownTables.make_table(headers,
                                                rules,
                                                is_rows: true,
                                                align: 'l')
        end

        headers = ['WAF ACL Name', 'ID', 'Resource']
        if resources.empty?
          resource_info = 'N/A'
        else
          resource_info = MarkdownTables.make_table(headers,
                                                    resources,
                                                    is_rows: true,
                                                    align: 'l')
        end

        headers = ['IP Set ID', 'IP Set Name', 'Value']
        if ip_sets.empty?
          ip_sets_info = 'N/A'
        else
          ip_sets_info = MarkdownTables.make_table(headers,
                                                   ip_sets,
                                                   is_rows: true,
                                                   align: 'l')
        end

        documents = <<"EOS"
### WAF (v2)

#### Web ACL

#{web_acl_info}

#### Rules

#{rule_info}

#### Resources

#{resource_info}

#### IP Sets

#{ip_sets_info}
EOS
        documents
      end

      def get_resources
        client = Aws::WAFV2::Client.new

        web_acls = []
        rules = []
        resources = []

        # TODO: iteration in case over limit
        all_web_acls = []
        begin
          all_web_acls.concat(client.list_web_acls({ scope: 'CLOUDFRONT', limit:100 }).web_acls.map(&:to_h).each { |a| a[:scope]='CLOUDFRONT'; a })
        rescue Aws::WAFV2::Errors::WAFInvalidParameterException => e
          # pass (WAF not found)
        end
        begin
        all_web_acls.concat(client.list_web_acls({ scope: 'REGIONAL', limit:100 }).web_acls.map(&:to_h).each { |a| a[:scope]='REGIONAL'; a })
        rescue Aws::WAFV2::Errors::WAFInvalidParameterException => e
          # pass (WAF not found)
        end

        all_web_acls.each do |wa|
          # web_acl
          web_acl = []
          web_acl << wa[:scope]
          web_acl << wa[:name]
          web_acl << wa[:id]
          web_acl << wa[:description]
          web_acls << web_acl

          # web_acl => rules
          wacl = client.get_web_acl({ name: wa[:name], scope: wa[:scope], id: wa[:id] }).web_acl
          web_acl_arn = wacl.arn
          wacl.rules.map(&:to_h).each do |r|
            rule = []
            rule << wa[:name]
            rule << wa[:id]
            rule << r[:name]
            rule << r[:priority]
            rule << JSON.dump(r[:statement])

            rules << rule
          end

          # web_acl => resources
          resource = []
          resource.concat(client.list_resources_for_web_acl({ web_acl_arn: web_acl_arn, resource_type: 'APPLICATION_LOAD_BALANCER' }).resource_arns)
          resource.concat(client.list_resources_for_web_acl({ web_acl_arn: web_acl_arn, resource_type: 'API_GATEWAY' }).resource_arns)
          resource.concat(client.list_resources_for_web_acl({ web_acl_arn: web_acl_arn, resource_type: 'APPSYNC' }).resource_arns)
          resource.each do |r|
            resources << [wa[:name], wa[:id], r.split(':')[5..].join(':')]
          end

        end

        # ip_set
        ip_sets = []
        all_ip_sets = []

        # TODO: iteration in case over limit
        all_ip_sets = []
        begin
          all_ip_sets.concat(client.list_ip_sets({ scope: 'CLOUDFRONT', limit:100 }).ip_sets.map(&:to_h).each { |a| a[:scope]='CLOUDFRONT'; a })
        rescue Aws::WAFV2::Errors::WAFInvalidParameterException => e
          # pass (IP Set not found)
        end
        begin
        all_ip_sets.concat(client.list_ip_sets({ scope: 'REGIONAL', limit:100 }).ip_sets.map(&:to_h).each { |a| a[:scope]='REGIONAL'; a })
        rescue Aws::WAFV2::Errors::WAFInvalidParameterException => e
          # pass (IP Set not found)
        end
        p all_ip_sets

        all_ip_sets.each do |i|
          r = client.get_ip_set({ name: i[:name], scope: i[:scope], id: i[:id] })
          ip_set = []
          ip_set << r.ip_set.id
          ip_set << r.ip_set.name

          if r.ip_set.addresses.empty?
            ip_set << ''
          else
            ip_set << r.ip_set.addresses.join(', ')
          end

          ip_sets << ip_set
        end

        return web_acls.sort, rules, resources.sort, ip_sets.sort
      end

      module_function :report, :get_resources
    end
  end
end

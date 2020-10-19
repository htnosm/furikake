module Furikake
  module Resources
    module IamRoleExcludeServiceRole
      def report
        resources = get_resources
        headers = ['Role Name', 'Path', 'Description', 'Trusted Entitles', 'Inline Policies', 'Managed Policies']
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### IAM Role (exclude AWS ServiceRole)

#{info}
EOS
        
        documents
      end

      def get_resources
        iam = Aws::IAM::Client.new

        req = {}
        iam_roles = []
        loop do
          res = iam.list_roles(req)
          iam_roles.push(*res.roles)
          break unless res.is_truncated
          req[:marker] = res.marker
        end

        iam_role_infos = []
        iam_roles.map(&:to_h).each do |i|
          next if i[:path].match(/\/(aws-)?service-role\//)
          iam_role = []
          iam_role << i[:role_name]
          iam_role << i[:path]
          iam_role << i[:description]

          trusted_entities = []
          assume_role_policy_document = JSON.parse(CGI.unescape(i[:assume_role_policy_document]))
          assume_role_policy_document['Statement'].each do |s|
            s['Principal'].each do |key, value|
              if value.instance_of?(Array)
                trusted_entities.concat(value)
              else
                trusted_entities << value
              end
            end
          end
          iam_role << trusted_entities.sort.join('<br>')

          req_inline_policies = {}
          inline_policies = []
          loop do
            res = iam.list_role_policies({role_name: i[:role_name]})
            inline_policies.push(*res.policy_names)
            break unless res.is_truncated
            req_inline_policies[:marker] = res.marker
          end
          iam_role << inline_policies.sort.join('<br>')

          req_managed_policies = {}
          managed_policies = []
          loop do
            res = iam.list_attached_role_policies({role_name: i[:role_name]})
            res.attached_policies.each do |p|
              managed_policies << p['policy_name']
            end
            break unless res.is_truncated
            req_managed_policies[:marker] = res.marker
          end
          iam_role << managed_policies.sort.join('<br>')

          iam_role_infos << iam_role
        end
        iam_role_infos.sort
      end

      module_function :report, :get_resources
    end
  end
end

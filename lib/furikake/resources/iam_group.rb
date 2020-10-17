module Furikake
  module Resources
    module IamGroup
      def report
        resources = get_resources
        headers = ['Group Name', 'Path', 'Inline Policies', 'Managed Policies']
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### IAM Group

#{info}
EOS
        
        documents
      end

      def get_resources
        iam = Aws::IAM::Client.new

        req = {}
        iam_groups = []
        loop do
          res = iam.list_groups(req)
          iam_groups.push(*res.groups)
          break unless res.is_truncated
          req[:marker] = res.marker
        end

        iam_group_infos = []
        iam_groups.map(&:to_h).each do |i|
          iam_group = []
          iam_group << i[:group_name]
          iam_group << i[:path]

          req_inline_policies = {}
          inline_policies = []
          loop do
            res = iam.list_group_policies({group_name: i[:group_name]})
            inline_policies.push(*res.policy_names)
            break unless res.is_truncated
            req_inline_policies[:marker] = res.marker
          end
          iam_group << inline_policies.sort.join('<br>')

          req_managed_policies = {}
          managed_policies = []
          loop do
            res = iam.list_attached_group_policies({group_name: i[:group_name]})
            res.attached_policies.each do |p|
              managed_policies << p['policy_name']
            end
            break unless res.is_truncated
            req_managed_policies[:marker] = res.marker
          end
          iam_group << managed_policies.sort.join('<br>')

          iam_group_infos << iam_group
        end
        iam_group_infos.sort
      end

      module_function :report, :get_resources
    end
  end
end

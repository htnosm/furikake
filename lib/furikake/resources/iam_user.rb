module Furikake
  module Resources
    module IamUser
      def report
        resources = get_resources
        headers = ['User Name', 'Path', 'Groups', 'Inline Policies', 'Managed Policies']
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### IAM User

#{info}
EOS
        
        documents
      end

      def get_resources
        iam = Aws::IAM::Client.new

        req = {}
        iam_users = []
        loop do
          res = iam.list_users(req)
          iam_users.push(*res.users)
          break unless res.is_truncated
          req[:marker] = res.marker
        end

        iam_user_infos = []
        iam_users.map(&:to_h).each do |i|
          iam_user = []
          iam_user << i[:user_name]
          iam_user << i[:path]

          groups = []
          list_groups = iam.list_groups_for_user({user_name: i[:user_name]})
          list_groups['groups'].each do |g|
            groups << g['group_name']
          end
          iam_user << groups.join('<br>')

          req_inline_policies = {}
          inline_policies = []
          loop do
            res = iam.list_user_policies({user_name: i[:user_name]})
            inline_policies.push(*res.policy_names)
            break unless res.is_truncated
            req_inline_policies[:marker] = res.marker
          end
          iam_user << inline_policies.sort.join('<br>')

          req_managed_policies = {}
          managed_policies = []
          loop do
            res = iam.list_attached_user_policies({user_name: i[:user_name]})
            res.attached_policies.each do |p|
              managed_policies << p['policy_name']
            end
            break unless res.is_truncated
            req_managed_policies[:marker] = res.marker
          end
          iam_user << managed_policies.sort.join('<br>')

          iam_user_infos << iam_user
        end
        iam_user_infos.sort
      end

      module_function :report, :get_resources
    end
  end
end

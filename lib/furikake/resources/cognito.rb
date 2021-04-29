require "json"

module Furikake
  module Resources
    module Cognito
      def report
        user_pools = get_resources

        headers = ['Name', 'ARN']
        if user_pools.empty?
          user_pool_info = 'N/A'
        else
          user_pool_info = MarkdownTables.make_table(headers,
                                                     user_pools,
                                                     is_rows: true,
                                                     align: 'l')
        end

        documents = <<"EOS"
### Cognito

#### User Pool

#{user_pool_info}
EOS
        documents
      end

      def get_resources
        client = Aws::CognitoIdentityProvider::Client.new

        user_pools = []

        # TODO: iteration in case over limit
        client.list_user_pools({ max_results: 60 }).user_pools.map(&:to_h).each do |up|
          user_pool = []
          user_pool << up[:name]
          user_pool << client.describe_user_pool({ user_pool_id: up[:id] }).user_pool.arn
          user_pools << user_pool
        end

        return user_pools.sort
      end

      module_function :report, :get_resources
    end
  end
end

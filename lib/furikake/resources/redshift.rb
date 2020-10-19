module Furikake
  module Resources
    module Redshift
      def report(format = nil)
        cluster = get_resources
        contents = {
          title: 'Redshift',
          resources: [
              {
                 subtitle: 'Clusters',
                 header: ['Cluster Identifier', 'Endpoint', 'Node Type', 'Status(AvailabilityStatus)',
                          'Number Of Nodes', 'JDBC URL', 'ODBC URL'],
                 resource: cluster
              }
          ]
        }
        Furikake::Formatter.shaping(format, contents).chomp
      end

      def get_resources
        redshift = Aws::Redshift::Client.new

        cluster_infos = []
        redshift.describe_clusters.clusters.map(&:to_h).each do |c|
          cluster = []
          cluster << c[:cluster_identifier]
          endpoint = "#{c[:endpoint][:address]}:#{c[:endpoint][:port]}/#{c[:db_name]}"
          cluster << endpoint
          cluster << c[:node_type]
          cluster << "#{c[:cluster_status]}(#{c[:cluster_availability_status]})"
          cluster << c[:number_of_nodes]
          # Add space to both end for backlog markdown table parse
          cluster << " jdbc:redshift://#{endpoint} "
          odbc_url = " Driver={Amazon Redshift (x64)}; Server=#{c[:endpoint][:address]}; Database=#{c[:db_name]};UID=#{c[:master_username]}; PWD=insert_your_master_user_password_here; Port=#{c[:endpoint][:port]} "
          cluster << odbc_url
          cluster_infos << cluster
        end

        cluster_infos.sort
      end

      module_function :report, :get_resources
    end
  end
end

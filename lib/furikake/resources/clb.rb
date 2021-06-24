module Furikake
  module Resources
    module Clb
      def report
        resources, listeners = get_resources
        headers = ['LB Name', 'DNS Name', 'Instances', 'Security Group']
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end

        headers = ['LB Name', 'Load Balancer Protocol', 'Load Balancer Port', 'Instance Protocol', 'Instance Port', 'SSL Certificate']
        if listeners.empty?
          listener_info = 'N/A'
        else
          listener_info = MarkdownTables.make_table(headers,
                                                        listeners,
                                                        is_rows: true,
                                                        align: 'l')
        end

        documents = <<"EOS"
### ELB (CLB)

#{info}

#### Listeners

#{listener_info}

EOS
        
        documents
      end

      def get_resources
        elb = Aws::ElasticLoadBalancing::Client.new
        elbs = []
        listeners = []
        elb.describe_load_balancers.load_balancer_descriptions.each do |lb|
          elb = []
          elb << lb.load_balancer_name
          elb << lb.dns_name
          elb << (lb.instances.map(&:to_h).map {|a| a[:instance_id] }).join(',')
          elb << lb.security_groups.sort.join('<br>')
          elbs << elb

          listener = []
          lb.listener_descriptions.each do |l|
            listener << lb.load_balancer_name
            listener << l.listener.protocol
            listener << l.listener.load_balancer_port
            listener << l.listener.instance_protocol
            listener << l.listener.instance_port
            listener << l.listener.ssl_certificate_id
          end
          listeners << listener
        end
        return elbs.sort, listeners.sort
      end

      module_function :report, :get_resources
    end
  end
end

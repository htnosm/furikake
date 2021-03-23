require "json"

module Furikake
  module Resources
    module Alb
      def report
        albs, listeners, rules, target_groups = get_resources
        headers = ['LB Name', 'DNS Name', 'Type', 'Target Group']
        if albs.empty?
          albs_info = 'N/A'
        else
          albs_info = MarkdownTables.make_table(headers,
                                                albs,
                                                is_rows: true,
                                                align: 'l')
        end
        
        headers = ['Listener Name', 'Protocal', 'Port', 'Listener Name']
        if listeners.empty?
          listener_info = 'N/A'
        else
          listener_info = MarkdownTables.make_table(headers,
                                                        listeners,
                                                        is_rows: true,
                                                        align: 'l')
        end

        headers = ['Listener Name', 'Priority', 'Conditions', 'Actions']
        if rules.empty?
          rule_info = 'N/A'
        else
          rule_info = MarkdownTables.make_table(headers,
                                                        rules,
                                                        is_rows: true,
                                                        align: 'l')
        end

        headers = ['Target Group Name', 'Protocal', 'Port', 'Health Check Path', 'Health Chack Port', 'Health Check Protocol']
        if target_groups.empty?
          target_group_info = 'N/A'
        else
          target_group_info = MarkdownTables.make_table(headers,
                                                        target_groups,
                                                        is_rows: true,
                                                        align: 'l')
        end
        
        documents = <<"EOS"
### ELB (ALB / NLB)

#### ALB / NLB

#{albs_info}

#### Listeners

#{listener_info}

#### Rules

#{rule_info}

#### Target Groups

#{target_group_info}
EOS
        documents
      end

      def get_resources
        alb = Aws::ElasticLoadBalancingV2::Client.new

        albs = []
        target_groups = []
        listeners = []
        rules = []
        alb.describe_load_balancers.load_balancers.each do |lb|
          alb_info = []
          t = alb.describe_target_groups({
                                          load_balancer_arn: lb.load_balancer_arn
                                         }).target_groups.map(&:to_h)
          alb_info << lb.load_balancer_name
          alb_info << lb.dns_name
          alb_info << lb.type
          alb_info << (t.map {|a| a[:target_group_name]}).join(", ")
          albs << alb_info

          # ALB => Listener
          # https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/ElasticLoadBalancingV2/Client.html#describe_listeners-instance_method
          l = alb.describe_listeners({
                                       load_balancer_arn: lb.load_balancer_arn
                                     }).listeners.map(&:to_h)
          l.each do |el|
            listener = []
            listener << el[:listener_arn].split('/')[2..].join('/')
            listener << el[:protocol]
            listener << el[:port]
            listeners << listener
          end

          # Listener => Rule
          # https://docs.aws.amazon.com/sdk-for-ruby/v2/api/Aws/ElasticLoadBalancingV2/Client.html#describe_rules-instance_method
          l.each do |el|
            r = alb.describe_rules({
                                     listener_arn: el[:listener_arn],
                                     page_size: 400
                                   }).rules.map(&:to_h)
            r.each do |er|
              rule = []
              rule << el[:listener_arn].split('/')[2..].join('/')
              rule << er[:priority]
              rule << JSON.dump(er[:conditions])
              rule << JSON.dump(er[:actions])
              rules << rule
            end
          end

          # ALB => Target Group
          target_group = []
          target_group << (t.map {|a| a[:target_group_name]}).join(", ")
          target_group << (t.map {|a| a[:protocol]}).join(", ")
          target_group << (t.map {|a| a[:port]}).join(", ")
          target_group << (t.map {|a| a[:health_check_path].nil? ? " " : a[:health_check_path]}).join(", ")
          target_group << (t.map {|a| a[:health_check_port]}).join(", ")
          target_group << (t.map {|a| a[:health_check_protocol]}).join(", ")
          target_groups << target_group
        end

        return albs.sort, listeners.sort, rules, target_groups.sort
      end

      module_function :report, :get_resources
    end
  end
end

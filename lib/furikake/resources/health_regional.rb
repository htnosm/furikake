# encoding: utf-8

module Furikake
  module Resources
    module HealthRegional
      def report
        current_region = get_current_region
        begin
          resources = get_resources(current_region)
          headers = [
            'EventType',
            'StartTime',
            'LastUpdateTime',
            'Status',
            'EventType'
          ]
          if resources.empty?
            info = 'N/A'
          else
            info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
          end
        rescue Aws::Health::Errors::SubscriptionRequiredException
          info = "SubscriptionRequiredException: ビジネスまたはエンタープライズのAWSサポートプランが必要です."
        end
        documents = <<"EOS"
### Health Events (Open/#{current_region})

#{info}
EOS
        
        documents
      end

      def get_resources(region)
        health = Aws::Health::Client.new(region: 'us-east-1')
        params = {
          filter: {
            regions: [region],
            # accepts issue, accountNotification, scheduledChange, investigation
            event_type_categories: ['issue', 'scheduledChange', 'investigation'],
            # accepts open, closed, upcoming
            event_status_codes: ['open', 'upcoming'],
          },
          # between 10 and 100
          max_results: 100,
        }
        res = health.describe_events(params)

        events = []
        res.events.each do |r|
            event = []
            event << r.event_type_code
            event << r.start_time
            event << r.last_updated_time
            event << r.status_code
            event << r.event_type_category
            events << event
        end
        events
      end

      def get_current_region
        ec2 =  Aws::EC2::Client.new()
        resp = ec2.describe_subnets()
        az = resp.subnets[0].availability_zone
        current_region = az.slice(/^([a-z]{2}-[a-z|-]*-\d)/)

        current_region
      end

      module_function :report, :get_resources, :get_current_region
    end
  end
end

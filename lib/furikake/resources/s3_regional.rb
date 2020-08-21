# encoding: utf-8

module Furikake
  module Resources
    module S3Regional
      def report
        current_region = get_current_region
        resources = get_resources(current_region)
        headers = [
          'BucketName',
          'Region',
        ]
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### S3 Bucket (#{current_region})

#{info}
EOS
        
        documents
      end

      def get_resources(region)
        s3 = Aws::S3::Client.new()
        params = {}
        res = s3.list_buckets(params)
        buckets = []
        res.buckets.each do |b|
          bucket = []
          bucket << b.name

          # bucket_location
          location = s3.get_bucket_location({
            bucket: b.name, 
          })
          if location.location_constraint == ""
            location.location_constraint = 'us-east-1'
          end
          bucket << location.location_constraint

          if location.location_constraint == region
            buckets << bucket
          end
        end
        buckets.sort
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

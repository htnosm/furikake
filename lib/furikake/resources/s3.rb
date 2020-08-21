# encoding: utf-8

module Furikake
  module Resources
    module S3
      def report
        resources = get_resources
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
### S3 Bucket

#{info}
EOS
        
        documents
      end

      def get_resources
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

          buckets << bucket
        end
        buckets.sort
      end

      module_function :report, :get_resources
    end
  end
end

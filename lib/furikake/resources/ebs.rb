module Furikake
  module Resources
    module Ebs
      def report(format = nil)
        volumes = get_resources
        contents = {
          title: 'EBS',
          resources: [
            {
               subtitle: '',
               header: ['Name', 'Volume ID', 'Size(GiB)', 'Volume Type', 'IOPS',
                        'Availability Zone', 'State',
                        'Attachment information'],
               resource: volumes.sort
            }
          ]
        }
        if $output_tag_keys and $output_tag_keys.length > 0
          contents[:resources][0][:header] << 'Tags'
        end
        Furikake::Formatter.shaping(format, contents)
      end

      def get_resources
        ec2 = Aws::EC2::Client.new
        params = {}
        params[:filters] = $filters
        volumes = []
        loop do
          res = ec2.describe_volumes(params)
          res.volumes.each do |v|
            volume = []
            volume << 'N/A' if v.tags.map(&:to_h).all? { |h| h[:key] != 'Name' }
            v.tags.each do |tag|
              volume << tag.value if tag.key == 'Name'
            end
            volume << v.volume_id
            volume << v.size
            volume << v.volume_type
            volume << v.iops
            volume << v.availability_zone
            volume << v.state

            attachments = []
            v.attachments.each do |a|
              attachment = []
              attachment << a.instance_id
              attachment << a.device
              attachment << a.state
              attachments << attachment.join(':')
            end
            volume << attachments.join('<br>')

            if $output_tag_keys
              output_tags = []
              $output_tag_keys.each do |t|
                v.tags.each do |tag|
                  output_tags << '"' + t + '":"' + tag.value + '"' if tag.key == t
                end
              end
              volume << output_tags.sort.join('<br>')
            end

            volumes << volume
          end
          break if res.next_token.nil?
          params[:next_token] = res.next_token
        end

        volumes.sort
      end
      module_function :report, :get_resources
    end
  end
end

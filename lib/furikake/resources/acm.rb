module Furikake
  module Resources
    module Acm
      def report
        resources = get_resources
        headers = [
          'Name',
          'Domain Name',
          'Additional Names',
          'Status',
          'Type',
          'In Use Count',
          'Renewal Eligibility',
          'Validation Method',
        ]
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### ACM

#{info}
EOS
        
        documents

      end

      def get_resources
        aws_acm = Aws::ACM::Client.new
        params = {}
        acms = []
        loop do
          res = aws_acm.list_certificates(params)
          res.certificate_summary_list.each do |c|
            acm = []

            res_tags = aws_acm.list_tags_for_certificate({
              certificate_arn: c.certificate_arn
            })
            acm << 'N/A' if res_tags.tags.map(&:to_h).all? { |h| h[:key] != 'Name' }
            res_tags.tags.each do |tag|
              acm << tag.value if tag.key == 'Name'
            end

            acm << c.domain_name

            res_cert = aws_acm.describe_certificate({
              certificate_arn: c.certificate_arn
            })
            cert = res_cert.certificate
            acm << cert.subject_alternative_names.sort.join('<br>')
            acm << cert.status
            acm << cert.type
            acm << cert.in_use_by.length
            acm << cert.renewal_eligibility
            acm << cert.domain_validation_options[0].validation_method
            acms << acm
          end
          break if res.next_token.nil?
          params[:next_token] = res.next_token
        end
        acms.sort
      end
      module_function :report, :get_resources
    end
  end
end

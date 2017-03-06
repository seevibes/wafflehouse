require "external_service_new/mailchimp_list_members_response"

module ExternalServiceNew
  class MailchimpDownloader

    attr_reader :logger, :dispatcher, :importer
    def initialize(dispatcher:, logger: nil, importer: nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher  = dispatcher
      @importer    = importer
      @logger      = logger || respond_to?(:logger) ? logger : nil
    end

    def each_list(&block)

      return to_enum(:each_list) unless block
      response = dispatcher.dispatch(:get, "lists/")

      lists = response["lists"].map{ |list| list.deep_symbolize_keys }

      lists.each do |list|
        block.call(list[:id], list[:name], list[:stats][:member_count])
      end
    end

    def each_email(id:, filters: nil, &block)
      return to_enum(:each_email) unless block

      mailing_list_infos = dispatcher.dispatch(:get, "lists/#{id}")

      offset = 0
      while offset < mailing_list_infos["stats"]["member_count"] do
        response = dispatcher.dispatch(:get, "lists/#{id}/members?count=1000&offset=#{offset}&fields[]=email_address,stats")
        break if response["members"].empty?

        response = ExternalServiceNew::MailchimpListMembersResponse.new(response["members"])
        response.each_valid_email {|email|  yield email }

        importer.import_emails_with_metadata(response) if importer

        offset += response.size
      end

      importer.notify_end_of_response_from_external_service if importer
    end
  end
end
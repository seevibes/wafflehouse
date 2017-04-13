require "external_service_new/hubspot_contacts_response"

module ExternalServiceNew
  class HubspotDownloader

    ALL_EMAILS_ID = "all_emails"
    ALL_EMAILS_AS_A_LIST = { listId: ALL_EMAILS_ID, name: "All Emails", metaData: { size: nil }}

    attr_reader :dispatcher, :importer, :logger
    def initialize(dispatcher:, importer: nil, logger:nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher = dispatcher
      @importer   = importer
      @logger     = logger || respond_to?(:logger) ? logger : nil
    end

    def each_list(&block)
      return to_enum(:each_list) unless block

      offset = 0
      loop do
        response = dispatcher.dispatch(:get, "/contacts/v1/lists?count=1000&offset=#{offset}").deep_symbolize_keys

        # Pulling all emails as a unique customer list is a use case for accounts that have no lists (CRM accounts), let's not interfere otherwise...
        if response[:lists].empty?
          response[:lists] << ALL_EMAILS_AS_A_LIST
        end

        response[:lists].each do |list|
          block.call(list[:listId], list[:name], list[:metaData][:size])
        end

        break unless response[:"has-more"]
        offset += response[:offset]
      end
    end

    def each_email(id:, filters: nil, &block)
      return to_enum(:each_email) unless block

      logger && logger.info("Downloading Hubspot Contact List #{id.inspect}")

      offset = 0
      loop do
        logger && logger.debug{ "Requesting Hubspot Contact List #{id.inspect} starting at offset #{offset}" }

        response =
          if id == ALL_EMAILS_ID
            dispatcher.dispatch(:get, "/contacts/v1/lists/all/contacts/all?count=250&vidOffset=#{offset}&property=email")
          else
            dispatcher.dispatch(:get, "/contacts/v1/lists/#{id}/contacts/all?count=250&vidOffset=#{offset}&property=email")
          end

        response = HubspotContactsResponse.new(response)
        response.each_valid_email { |email| yield email }
        importer.import_emails_with_metadata(response) if importer

        break unless response.has_more?
        offset = response.vid_offset
      end

      logger && logger.debug{ "Done downloading Hubspot Contact List #{id.inspect}" }
      importer.notify_end_of_response_from_external_service if importer
    end
  end
end

module ExternalServiceNew
  class ZendeskDownloader
    def initialize(dispatcher:, logger:nil)
      @dispatcher = dispatcher
      @logger     = logger
    end

    def each_list(&block)
      return to_enum(:each_list) unless block
      [[
        dispatcher.site_url,
        "#{dispatcher.site_url}'s customers"
      ]].each(&block)
    end

    def each_email(id: nil, &block)
      ZendeskInternalDownloader.new(
        dispatcher: dispatcher,
        logger: logger
      ).each_email(&block)
    end

    private

    attr_reader :dispatcher, :logger
  end

  class ZendeskInternalDownloader
    def initialize(dispatcher:, filters: nil, logger:nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher = dispatcher
      @filters = filters
      @logger = logger
    end

    def each_email(&block)
      return to_enum(:each_email) unless block
      logger && logger.info("Downloading Zendesk Customer List with #{filters ? filters.inspect : "no filters"}")

      response = dispatcher.dispatch(:query, "type:user role:end-user")
      response.each {|contact| yield(contact["email"])}

      logger && logger.info("Downloaded Zendesk )Customer List")
    end

    private

    attr_reader :dispatcher, :filters, :logger
  end
end

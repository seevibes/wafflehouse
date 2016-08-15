module ExternalServiceNew
  class ZendeskDownloader
    def initialize(dispatcher:, logger:nil)
      @dispatcher = dispatcher
      @logger     = logger
    end

    def each_list(&block)
      return to_enum(:each_list) unless block
      # We are putting all emails in just one list that we create
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
    # maximum of 100 records per page
    PER_PAGE = 100
    def initialize(dispatcher:, filters: nil, logger:nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher = dispatcher
      @filters = filters
      @logger = logger
    end

    def each_email(&block)
      page = 1
      return to_enum(:each_email) unless block
      logger && logger.info("Downloading Zendesk Customer List with #{filters ? filters.inspect : "no filters"}")

      loop do
        response = dispatcher.dispatch(:query, each_email_path).per_page(PER_PAGE).page(page).fetch
        break if response.empty?
        response.each{|contact| yield(contact["email"])}

        page +=1
      end

      logger && logger.info("Downloaded Zendesk )Customer List")
    end

    private

    def each_email_path
      "type:user role:end-user"
    end
    attr_reader :dispatcher, :filters, :logger
  end
end

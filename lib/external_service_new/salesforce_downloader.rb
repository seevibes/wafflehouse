module ExternalServiceNew

  FILTERED_ACCOUNTS = [
    "0013600000PwiqJAAR",
    "0013600000PwiqKAAR",
    "0013600000PwiqLAAR",
    "0013600000PwiqMAAR",
    "0013600000PwiqNAAR",
    "0013600000PwiqOAAR",
    "0013600000PwiqPAAR",
    "0013600000PwiqQAAR",
    "0013600000PwiqRAAR",
    "0013600000PwiqSAAR",
    "0013600000PwiqTAAR",
    "0013600000PwiqUAAR"
  ]

  class SalesforceDownloader


    def initialize(dispatcher:, logger:nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher = dispatcher
      @logger     = logger || respond_to?(:logger) ? logger : nil
    end

    def each_list(&block)
      return to_enum(:each_list) unless block
      email_count_object = dispatcher.dispatch(:query, "SELECT count(email) FROM Contact WHERE Email != NULL AND AccountId NOT IN ('#{FILTERED_ACCOUNTS.join("', '")}')")
      email_count = email_count_object.first["expr0"]
      [[
         dispatcher.account_name,
         "#{dispatcher.account_name}'s customers",
         email_count
       ]].each(&block)
    end

    def each_email(id: nil, &block)
      SalesforceInternalDownloader.new(dispatcher: dispatcher, logger: logger).each_email(&block)
    end

    private

    attr_reader :dispatcher, :logger
  end

  class SalesforceInternalDownloader
    def initialize(dispatcher:, filters: nil, logger:nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher = dispatcher
      @filters    = filters
      @logger     = logger || respond_to?(:logger) ? logger : nil
    end

    def each_email(&block)
      return to_enum(:each_email) unless block

      logger && logger.info("Downloading Salesforce Customer List with #{filters ? filters.inspect : "no filters"}")

      response = dispatcher.dispatch(:query, "SELECT email FROM Contact WHERE Email != NULL AND AccountId NOT IN ('#{FILTERED_ACCOUNTS.join("', '")}')")
      response.each {|email| yield email["Email"] }

      logger && logger.info("Downloaded Shopify Customer List")
    end

    private

    attr_reader :dispatcher, :filters, :logger
  end
end

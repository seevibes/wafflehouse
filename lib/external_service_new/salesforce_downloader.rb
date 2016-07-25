module ExternalServiceNew
  class SalesforceDownloader
    def initialize(dispatcher:, logger:nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher = dispatcher
      @logger     = logger || respond_to?(:logger) ? logger : nil
    end

    def each_list(&block)
      return to_enum(:each_list) unless block
      email_count =  dispatcher.dispatch(:count, "Contact")

      [[
         dispatcher.account_id,
         "#{dispatcher.account_id}'s customers",
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

      response = dispatcher.dispatch(:all, "Contact")
      response.each {|contact| yield contact["Email"] }

      logger && logger.info("Downloaded Shopify Customer List")
    end

    private

    attr_reader :dispatcher, :filters, :logger
  end
end

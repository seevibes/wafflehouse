module ExternalServiceNew
  class ShopifyDownloader
    def initialize(dispatcher:, logger:nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher = dispatcher
      @logger     = logger || respond_to?(:logger) ? logger : nil
    end

    def each_list(&block)
      return to_enum(:each_list) unless block
      email_count_response =  dispatcher.dispatch(:get, "/admin/customers/count.json")

      [[
        dispatcher.shop_url,
        "#{dispatcher.shop_url}'s customers",
        email_count_response["count"]
      ]].each(&block)
    end

    def each_email(id:, &block)
      ShopifyInternalDownloader.new(dispatcher: dispatcher, filters: id, logger: logger).each_email(&block)
    end

    private

    attr_reader :dispatcher, :logger
  end

  class ShopifyInternalDownloader
    def initialize(dispatcher:, filters:, logger:nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher = dispatcher
      @filters    = filters
      @logger     = logger || respond_to?(:logger) ? logger : nil
    end

    def each_email(&block)
      return to_enum(:each_email) unless block

      logger && logger.info("Downloading Shopify Customer List with #{filters ? filters.inspect : "no filters"}")

      page = 1
      loop do
        response = dispatcher.dispatch(:get, "/admin/customers/search.json?page=#{page}&limit=250&fields=email")
        break if response["customers"].empty?

        response["customers"].each {|customer| yield customer["email"]}
        page += 1
      end

      logger && logger.info("Downloaded Shopify Customer List")
    end

    private

    attr_reader :dispatcher, :filters, :logger
  end
end

module ExternalService
  class ShopifyDownloader
    def initialize(dispatcher:, logger:nil)
      @dispatcher = dispatcher
      @logger     = logger || respond_to?(:logger) ? logger : nil
    end

    def each_list(&block)
      return to_enum(:each_list) unless block

      raise "TODO: implement this method"
    end

    def each_email(id:, &block)
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

    attr_reader :dispatcher, :logger
  end
end

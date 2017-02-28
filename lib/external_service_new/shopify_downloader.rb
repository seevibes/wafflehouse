require "external_service_new/shopify_customers_response"

module ExternalServiceNew
  class ShopifyDownloader

    LOCAL_FILTERS = [
      "average_basket_revenue_min",
      "average_basket_revenue_max",
      "created_at_min",
      "created_at_max",
      "total_spent_min",
      "total_spent_max",
      "orders_count_min",
      "orders_count_max",
      "updated_at_min",
      "updated_at_max"]

    REMOTE_FILTERS = [
      "city",
      "country",
      "province",
      "province_code",
      "zip"]

    def initialize(dispatcher:, logger: nil, importer: nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher = dispatcher
      @logger     = logger || respond_to?(:logger) ? logger : nil
      @importer   = importer
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

    def each_email(id: nil, filters: [], &block)
      @filters = filters
      raise unless validate_filters

      return to_enum(:each_email) unless block
      logger && logger.info("Downloading Shopify Customer List with #{filters.empty? ? 'no filters' : filters.inspect}")

      page = 1
      logger && (start_time = Time.now)
      loop do
        response = dispatcher.dispatch(:get, "/admin/customers/search.json?page=#{page}&limit=250&query= " + uri_format(remote_filters))
        break if response["customers"].empty?

        response = ExternalServiceNew::ShopifyCustomersResponse.new(batch_customers: response, local_filters: local_filters)
        response.each_valid_email {|email| yield email }

        importer.import_emails_with_metadata(response) if importer
        page += 1
      end

      importer.notify_end_of_response_from_external_service if importer

      logger && logger.info("Downloaded Shopify Customer List between #{start_time} and #{Time.now}")
    end


    private

    def local_filters
      @filters.select{|filter| LOCAL_FILTERS.include?(filter)}
    end

    def remote_filters
      @filters.select{|filter| REMOTE_FILTERS.include?(filter)}
    end

    def validate_filters
      @filters.all?{ |filter| !filter[:code].nil? && !filter[:value].nil? && (LOCAL_FILTERS.include?(filter) || REMOTE_FILTERS.include?(filter)) }
    end

    def uri_format(filters)
      filters.map{|f| "#{f[:code]}:#{f[:value]}"}.join(" ")
    end

    attr_reader :dispatcher, :logger, :importer
  end
end

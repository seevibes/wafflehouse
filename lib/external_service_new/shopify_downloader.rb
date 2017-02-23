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

    def each_email(filters: [], &block)
      ShopifyInternalDownloader.new(dispatcher: dispatcher, filters: filters, logger: logger).each_email(&block)
    end

    private

    attr_reader :dispatcher, :logger
  end

  class ShopifyInternalDownloader
    AFTER_REMOTE_FILTERS = [
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

    attr_reader :dispatcher, :logger
    def initialize(dispatcher:, filters:, logger:nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher           = dispatcher
      @remote_filters       = filters.select{|filter| REMOTE_FILTERS.include?(filter.fetch(:code))}
      @after_remote_filters = filters.select{|filter| AFTER_REMOTE_FILTERS.include?(filter.fetch(:code))}
      @logger               = logger || respond_to?(:logger) ? logger : nil
    end


    EMAIL_FIELDS = "email,orders_count,total_spent,created_at,updated_at"
    def each_email(&block)
      return to_enum(:each_email) unless block

      filter_log_message = (@remote_filters + @after_remote_filters).empty? ? 'no filters' : parse_filters(@remote_filters) + " " + parse_filters(@after_remote_filters)
      logger && logger.info("Downloading Shopify Customer List with #{filter_log_message}")

      page = 1
      loop do
        response = dispatcher.dispatch(:get, "/admin/customers/search.json?page=#{page}&limit=250&fields=#{EMAIL_FIELDS}&query= " + parse_filters(@remote_filters))
        break if response["customers"].empty?

        response["customers"].each do |shopify_customer|
          next unless matching_after_remote_filters(shopify_customer)

          yield shopify_customer["email"]
        end
        page += 1
      end

      logger && logger.info("Downloaded Shopify Customer List")
    end


    private

    def parse_filters(filters)
      filters.map{|f| "#{f.fetch(:code)}:#{f.fetch(:value)}"}.join(" ")
    end

    def matching_after_remote_filters(shopify_customer)
      shopify_customer["total_spent"] = shopify_customer["total_spent"].to_i
      shopify_customer["orders_count"] = shopify_customer["orders_count"].to_i
      shopify_customer["created_at"] = shopify_customer["created_at"].to_time
      shopify_customer["updated_at"] = shopify_customer["updated_at"].to_time

      @after_remote_filters.all? do |filter|
        self.send("check_#{filter.fetch(:code)}", shopify_customer, filter.fetch(:value))
      end
    end


    # AFTER_REMOTE_FILTER CHECKS

    def check_created_at_max(shopify_customer, time)
      shopify_customer["created_at"] <= time
    end

    def check_created_at_min(shopify_customer, time)
      shopify_customer["created_at"] >= time
    end

    def check_updated_at_max(shopify_customer, time)
      shopify_customer["updated_at"] <= time
    end

    def check_updated_at_min(shopify_customer, time)
      shopify_customer["updated_at"] >= time
    end

    def check_average_basket_revenue_max(shopify_customer, value)
      return false if shopify_customer["orders_count"] < 1

      (shopify_customer["total_spent"] / shopify_customer["orders_count"]) <= value.to_i
    end

    def check_average_basket_revenue_min(shopify_customer, value)
      return false if shopify_customer["orders_count"] < 1

      (shopify_customer["total_spent"] / shopify_customer["orders_count"]) >= value.to_i
    end

    def check_orders_count_max(shopify_customer, value)
      shopify_customer["orders_count"] <= value.to_i
    end

    def check_orders_count_min(shopify_customer, value)
      shopify_customer["orders_count"] >= value.to_i
    end

    def check_total_spent_max(shopify_customer, value)
      shopify_customer["total_spent"] <= value.to_i
    end

    def check_total_spent_min(shopify_customer, value)
      shopify_customer["total_spent"] >= value.to_i
    end
  end
end

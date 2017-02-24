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

    def each_email(id: nil, filters: [], &block)
      raise unless validate_filters(filters)

      ShopifyInternalDownloader.new(dispatcher: dispatcher, filters: filters, logger: logger).each_email(&block)
    end

    private

    def validate_filters(filters)
      filters.all?{ |filter| !filter[:code].ni? && !filter[:value].nil? }
    end

    attr_reader :dispatcher, :logger
  end

  class ShopifyInternalDownloader
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

    attr_reader :dispatcher, :logger
    def initialize(dispatcher:, filters: [], logger:nil)
      raise "dispatcher must not be nil}" unless dispatcher

      @dispatcher = dispatcher
      @filters    = filters
      @logger     = logger || respond_to?(:logger) ? logger : nil
    end


    EMAIL_FIELDS = "email,orders_count,total_spent,created_at,updated_at"
    def each_email(&block)
      return to_enum(:each_email) unless block

      logger && logger.info("Downloading Shopify Customer List with #{@filters.empty? ? 'no filters' : @filters.inspect}")

      remote_filters = filters_helper(REMOTE_FILTERS)
      page = 1
      loop do
        response = dispatcher.dispatch(:get, "/admin/customers/search.json?page=#{page}&limit=250&fields=#{EMAIL_FIELDS}&query= " + uri_format(remote_filters))
        break if response["customers"].empty?

        response["customers"].each do |customer_hash|
          next unless matching_local_filters(customer_hash)

          yield customer_hash["email"]
        end
        page += 1
      end

      logger && logger.info("Downloaded Shopify Customer List")
    end


    private

    def filters_helper(from)
      @filters.select{|filter| from.include?(filter)}
    end

    def uri_format(filters)
      filters.map{|f| "#{f[:code]}:#{f[:value]}"}.join(" ")
    end

    def matching_local_filters(customer_hash)
      customer_hash["total_spent"] = customer_hash["total_spent"].to_i
      customer_hash["orders_count"] = customer_hash["orders_count"].to_i
      customer_hash["created_at"] = customer_hash["created_at"].to_time
      customer_hash["updated_at"] = customer_hash["updated_at"].to_time

      filters_helper(LOCAL_FILTERS).all? do |filter|
        self.send("check_#{filter[:code]}", customer_hash, filter[:value])
      end
    end


    # LOCAL_FILTER CHECKS

    def check_created_at_max(customer_hash, time)
      customer_hash["created_at"] <= time
    end

    def check_created_at_min(customer_hash, time)
      customer_hash["created_at"] >= time
    end

    def check_updated_at_max(customer_hash, time)
      customer_hash["updated_at"] <= time
    end

    def check_updated_at_min(customer_hash, time)
      customer_hash["updated_at"] >= time
    end

    def check_average_basket_revenue_max(customer_hash, value)
      return false if customer_hash["orders_count"] < 1

      (customer_hash["total_spent"] / customer_hash["orders_count"]) <= value.to_i
    end

    def check_average_basket_revenue_min(customer_hash, value)
      return false if customer_hash["orders_count"] < 1

      (customer_hash["total_spent"] / customer_hash["orders_count"]) >= value.to_i
    end

    def check_orders_count_max(customer_hash, value)
      customer_hash["orders_count"] <= value.to_i
    end

    def check_orders_count_min(customer_hash, value)
      customer_hash["orders_count"] >= value.to_i
    end

    def check_total_spent_max(customer_hash, value)
      customer_hash["total_spent"] <= value.to_i
    end

    def check_total_spent_min(customer_hash, value)
      customer_hash["total_spent"] >= value.to_i
    end
  end
end

module ExternalServiceNew
  class ShopifyCustomersResponse
    def initialize(batch_customers: , local_filters: [])
      @customers      = batch_customers["customers"]
      @local_filters  = local_filters
    end

    def each_valid_email(&block)
      @customers.each do |customer|
        next if customer["email"].blank?
        next unless matching_local_filters(customer)

        yield customer["email"]
      end
    end

    def format_for_analytics
      customers_with_valid_emails.map do |customer|
        # Never store emails in clear text
        email_SHA256 = StringHelpers.normalized_SHA256(customer["email"])
        customer["email"] = email_SHA256

        [
          email_SHA256,
          'shopify',
          customer.to_json
        ]
      end
    end

    def customers_with_valid_emails
      @customers.select{|customer| !customer["email"].blank? }
    end


    private

    def matching_local_filters(customer)
      customer["total_spent"] = customer["total_spent"].to_i
      customer["orders_count"] = customer["orders_count"].to_i
      customer["created_at"] = customer["created_at"].to_time
      customer["updated_at"] = customer["updated_at"].to_time

      @local_filters.all? do |filter|
        self.send("check_#{filter[:code]}", customer, filter[:value])
      end
    end


    # LOCAL_FILTER CHECKS

    def check_created_at_max(customer, time)
      customer["created_at"] <= time
    end

    def check_created_at_min(customer, time)
      customer["created_at"] >= time
    end

    def check_updated_at_max(customer, time)
      customer["updated_at"] <= time
    end

    def check_updated_at_min(customer, time)
      customer["updated_at"] >= time
    end

    def check_average_basket_revenue_max(customer, value)
      return false if customer["orders_count"] < 1

      (customer["total_spent"] / customer["orders_count"]) <= value.to_i
    end

    def check_average_basket_revenue_min(customer, value)
      return false if customer["orders_count"] < 1

      (customer["total_spent"] / customer["orders_count"]) >= value.to_i
    end

    def check_orders_count_max(customer, value)
      customer["orders_count"] <= value.to_i
    end

    def check_orders_count_min(customer, value)
      customer["orders_count"] >= value.to_i
    end

    def check_total_spent_max(customer, value)
      customer["total_spent"] <= value.to_i
    end

    def check_total_spent_min(customer, value)
      customer["total_spent"] >= value.to_i
    end
  end
end
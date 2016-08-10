require "oj"
require "rest_client"
require "external_service_new/rest_client_dispatcher"
require "createsend"

module ExternalServiceNew
  class CreatesendDispatcher < RestClientDispatcher
    #maximum and minimun email fetch by page
    PAGE_SIZE_MAX = 1000
    PAGE_SIZE_MIN = 10

    def initialize(account_identifiers: nil, credential_details:, sleep_time_seconds: 5, client: RestClient)

      puts " CreatesendDispatcher initialize credential_details: #{credential_details}"
      @auth = {
        :access_token => credential_details.fetch(:oauth_token),
        :refresh_token => credential_details.fetch(:refresh_token)
      }

      cs = CreateSend::CreateSend.new @auth
      clients = cs.clients
      @client = CreateSend::Client.new @auth, clients[0].ClientID
    end

    #method = :lists will get the lists
    #method = :subscribers get the subscribers of a list
    def dispatch(method, id: nil, page: 1, page_size: PAGE_SIZE_MAX)
      super() do
        if (method == :lists)
          @client.lists
        elsif (method == :subscribers)
          if (page_size < PAGE_SIZE_MIN)
            page_size = PAGE_SIZE_MIN
          end
          list_client = CreateSend::List.new @auth, id
          list_client.active("", page, page_size, "email", "asc")
        end
      end
    end
  end
end

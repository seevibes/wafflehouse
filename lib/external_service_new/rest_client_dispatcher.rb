require "rest_client"

module ExternalServiceNew
  class BadRequest < RuntimeError ; end
  class Unauthorized < RuntimeError ; end
  class Forbidden < RuntimeError ; end
  #class NotFound < RuntimeError ; end
  class RateLimit < RuntimeError ; end
  class ServerError < RuntimeError ; end
  class ServiceUnavailable < RuntimeError ; end


  class RestClientDispatcher
    NB_RETRIES = 5

    def initialize(sleep_time_seconds=5)
      @retried = 0
      @sleep_time_seconds = sleep_time_seconds
    end

    def dispatch
      raise ArgumentError, "Missing block to delegate to" unless block_given?

      yield
    rescue RestClient::BadRequest => e
      raise BadRequest, "#{e.message}"
    rescue  Unauthorized,
            Forbidden,
            RateLimit,
            ServerError,
            ServiceUnavailable,
            Oj::ParseError,
            Errno::ECONNREFUSED,
            Errno::EHOSTUNREACH,
            Errno::ETIMEDOUT,
            RestClient::BadGateway,
            RestClient::GatewayTimeout,
            RestClient::InternalServerError,
            RestClient::Unauthorized,
            RestClient::ServiceUnavailable,
            SocketError => e

      respond_to?(:logger) && logger.warn("#{e.class}: #{e.message}")
      sleep @sleep_time_seconds

      @retried += 1
      @sleep_time_seconds  *= 2
    
      retry if @retried < NB_RETRIES

      raise BadRequest, "#{e.message}"
    end
  end
end

module ExternalServiceNew
  class MailchimpDownloader
    def initialize(dispatcher:, logger:nil, importer: nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher  = dispatcher
      @logger      = logger || respond_to?(:logger) ? logger : nil
    end

    def each_list(&block)

      return to_enum(:each_list) unless block
      response = dispatcher.dispatch(:get, "lists/")

      lists = response["lists"].map{ |list| list.deep_symbolize_keys }

      lists.each do |list|
        block.call(list[:id], list[:name], list[:stats][:member_count])
      end
    end

    def each_email(id:, filters: nil, &block)
      MailchimpInternalDownloader.new(dispatcher: dispatcher, id: id, logger: logger).each_email(&block)
    end

    private

    attr_reader :logger, :dispatcher
  end

  class MailchimpInternalDownloader
    def initialize(dispatcher:, id:, logger:nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher = dispatcher
      @id         = id
      @logger     = logger || respond_to?(:logger) ? logger : nil
    end

    def each_email(&block)
      return to_enum(:each_email) unless block

      mailing_list_infos = dispatcher.dispatch(:get, "lists/#{id}")

      offset = 0
      while offset < mailing_list_infos["stats"]["member_count"] do
        response = dispatcher.dispatch(:get, "lists/#{id}/members?count=1000&offset=#{offset}&fields[]=email_address,stats")
        members = response["members"]

        members.each {|member| yield member["email_address"]}

        if members.empty? then
          logger && logger.warn(<<-EOF)
            The members count we received is either empty (it should not!) or Mailchimp is bugged.
            Either way, converting whatever emails we have retrieved yet...
          EOF

          break
        end

        offset += members.size
      end
    end

    private

    attr_reader :logger, :id, :dispatcher
  end
end

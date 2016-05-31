module ExternalService
  class MailchimpDownloader
    def initialize(dispatcher:, logger:nil)
      @dispatcher  = dispatcher
      @logger      = logger || respond_to?(:logger) ? logger : nil
    end

    def each_list(&block)
      return to_enum(:each_list) unless block

      raise "TODO: implement this method"
    end

    def each_email(id:, &block)
      return to_enum(:each_email) unless block

      mailing_list_infos = dispatcher.dispatch(:get, "lists/#{external_id}")

      offset = 0
      while offset < mailing_list_infos["stats"]["member_count"] do

        response = dispatcher.dispatch(:get, "lists/#{external_id}/members?count=1000&offset=#{offset}&fields[]=email_address")
        members = response["members"]

        members.each {|member| yield member["email_address"]}

        if members.empty? then
          logger && logger.warn(<<-EOF)
            The members count we received is either empty (it should not!) or Mailchimp is bugged.
            Either way, converting whatever emails we have retreived yet...
          EOF

          break
        end

        offset += members.size
      end
    end

    private

    attr_reader :logger, :dispatcher
  end
end
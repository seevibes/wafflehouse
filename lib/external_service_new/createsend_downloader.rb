module ExternalServiceNew
  class CreatesendDownloader
    def initialize(dispatcher:, logger:nil)
      @dispatcher = dispatcher
      @logger     = logger
    end

    def each_list(&block)
      return to_enum(:each_list) unless block
      response = dispatcher.dispatch(:lists).each do |list|
        email_count = dispatcher.dispatch(:subscribers, id:list.ListID, page_size:10)
        block.call(list[:ListID], list[:Name], email_count[:TotalNumberOfRecords])
      end
    end

    def each_email(list_id:, &block)
      raise "list_id must not be nil" unless list_id
      CreatesendInternalDownloader.new(
        dispatcher: dispatcher,
        logger: logger
      ).each_email(list_id: list_id, &block)
    end

    private

    attr_reader :dispatcher, :logger
  end

  class CreatesendInternalDownloader
    def initialize(dispatcher:, filters: nil, logger:nil)
      raise "dispatcher must not be nil, found #{dispatcher.inspect}" unless dispatcher

      @dispatcher = dispatcher
      @filters = filters
      @logger = logger
    end

    def each_email(list_id:, &block)
      page = 1
      return to_enum(:each_email) unless block
      logger && logger.info("Downloading Campaign Monitor List with #{filters ? filters.inspect : "no filters"}")

      loop do
        response = dispatcher.dispatch(:subscribers, id: list_id, page: page)
        break if response[:Results].empty?
        response[:Results].each{|contact| yield(contact[:EmailAddress])}

        page +=1
      end

      logger && logger.info("Downloaded Campaign Monitor ListID: #{list_id}")
    end

    private

    attr_reader :dispatcher, :filters, :logger
  end
end

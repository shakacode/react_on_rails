# encoding: utf-8
module Mail
  class MessageIdsElement
    
    include Mail::Utilities
    
    def initialize(string)
      @message_ids = Mail::Parsers::MessageIdsParser.new.parse(string).message_ids.map { |msg_id| clean_msg_id(msg_id) }
    end
    
    def message_ids
      @message_ids
    end
    
    def message_id
      @message_ids.first
    end
    
    def clean_msg_id( val )
      val =~ /.*<(.*)>.*/ ; $1
    end

  end
end

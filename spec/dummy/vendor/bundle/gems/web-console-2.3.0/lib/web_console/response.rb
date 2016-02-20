module WebConsole
  # A response object that writes content before the closing </body> tag, if
  # possible.
  #
  # The object quacks like Rack::Response.
  class Response < Struct.new(:body, :status, :headers)
    def write(content)
      raw_body = Array(body).first.to_s

      if position = raw_body.rindex('</body>')
        raw_body.insert(position, content)
      else
        raw_body << content
      end

      self.body = raw_body
    end

    def finish
      Rack::Response.new(body, status, headers).finish
    end
  end
end

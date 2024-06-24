# frozen_string_literal: true

module TraceVisualizer
  class TraceVisualizerController < ActionController::Base
    def index
      log_file_path = "./log1.log"
      log_file_content = File.read(log_file_path)

      map_request_id_to_path = {}
      map_request_id_to_operation_stack = {}

      log_file_content.each_line do |line|
        # get lines like this:
        # [04b9a1be-1312-4053-9598-f500a81f0203] Started GET "/server_side_hello_world_hooks" for ::1 at 2024-06-24 12:27:08 +0300
        # it is a request start line.
        # Request id is between square brackets, request method is after "Started", request path is in quotes after method name.
        if line =~ /\[(\h{8}-\h{4}-\h{4}-\h{4}-\h{12})\] Started (\w+) "(.*)" for/
          request_id = ::Regexp.last_match(1)
          path = ::Regexp.last_match(3)
          map_request_id_to_path[request_id] = path
          map_request_id_to_operation_stack[request_id] = []
        end

        # Each operation logs the following line to logs
        # [04b9a1be-1312-4053-9598-f500a81f0203] [ReactOnRailsPro] [operation-start] PID:49996 server_rendering_component_js_code: HelloWorldHooks, 171923395.5230
        # where last number is the timestamp of the operation start
        # After finishing the operation it logs the following line
        # [04b9a1be-1312-4053-9598-f500a81f0203] [ReactOnRailsPro] PID:49996 server_rendering_component_js_code: HelloWorldHooks, 2.1ms
        # We need to extract the request id, operation name and duration of the operation
        # Also, we need to extract suboperations
        if line =~ /\[(\h{8}-\h{4}-\h{4}-\h{4}-\h{12})\] \[ReactOnRails\] \[operation-start\] PID:\d+ (\w+): (.*), (\d+\.\d+)/
          request_id = ::Regexp.last_match(1)
          operation_name = ::Regexp.last_match(2)
          message = ::Regexp.last_match(3)
          start_time = ::Regexp.last_match(4).to_f
          map_request_id_to_operation_stack[request_id] << {
            operation_name: operation_name,
            message: message,
            suboperations: [],
            start_time: start_time,
          }
        end

        next unless line =~ /\[(\h{8}-\h{4}-\h{4}-\h{4}-\h{12})\] \[ReactOnRails\] PID:\d+ (\w+): (.*), (\d+\.\d+)ms/

        # binding.pry
        request_id = ::Regexp.last_match(1)
        operation_name = ::Regexp.last_match(2)
        message = ::Regexp.last_match(3)
        duration = ::Regexp.last_match(4).to_f
        current_operation_in_stack = map_request_id_to_operation_stack[request_id].last

        if current_operation_in_stack[:operation_name] != operation_name || current_operation_in_stack[:message] != message
          raise "Unmatched operation name"
        end

        current_operation_in_stack[:duration] = duration
        if map_request_id_to_operation_stack[request_id].size > 1
          map_request_id_to_operation_stack[request_id].pop
          map_request_id_to_operation_stack[request_id].last[:suboperations] << current_operation_in_stack
        end
      end

      # render map_request_id_to_operation_stack to json
      # replace request ids with paths
      @json_data = map_request_id_to_operation_stack.map do |request_id, operation_stack|
        path = map_request_id_to_path[request_id]
        { path: path, operation_stack: operation_stack }
      end
      @json_data = @json_data.to_json

      # render the view in app/views/trace_visualizer/trace_visualizer/index.html.erb
      # with the json data
      render "index"
    end
  end
end

# frozen_string_literal: true

case ENV["MANUAL_EXECJS_RUNTIME"]
when "Node"
  ExecJS.runtime = ExecJS::Runtimes::Node
when "Alaska"
  require "alaska/runtime"
  ExecJS.runtime = Alaska::Runtime.new
when "MiniRacer"
  require "mini_racer"
  ExecJS.runtime = ExecJS::Runtimes::MiniRacer
end

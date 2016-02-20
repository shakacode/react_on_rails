original_handler = Pry.config.control_d_handler

Pry.config.control_d_handler = proc do |eval_string, pry_|
  Byebug.stop if Byebug.stoppable?

  original_handler.call(eval_string, pry_)
end

require "spec_helper"

describe "forking" do
  it do
    Process.waitpid(Kernel.fork {})
  end
end

require "rails_helper"

describe "Server Rendering" do
  it "generates server rendered HTML if server renderering enabled" do
    get server_side_hello_world_with_options_path
    html_nodes = Nokogiri::HTML(response.body)
    expect(html_nodes.css("div#my-hello-world-id").children.size).to eq(1)
    expect(html_nodes.css("div#my-hello-world-id h3").text)
      .to eq("Hello, Mr. Server Side Rendering!")
    expect(html_nodes.css("div#my-hello-world-id p input")[0]["value"])
      .to eq("Mr. Server Side Rendering")
  end

  it "generates no server rendered HTML if server renderering not enabled" do
    get client_side_hello_world_path
    html_nodes = Nokogiri::HTML(response.body)
    expect(html_nodes.css("div#HelloWorld-react-component-0").children.size).to eq(0)
  end
end

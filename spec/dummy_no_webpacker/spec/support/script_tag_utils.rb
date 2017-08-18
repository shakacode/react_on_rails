require 'equivalent-xml'

module ScriptTagUtils
  def script_tag_included?(parent_node, child_node)
    Nokogiri::HTML.fragment(parent_node).css("script").map{|script|
      EquivalentXml.equivalent?(Nokogiri::HTML.fragment(script.to_s), 
                                Nokogiri::HTML.fragment(child_node))
    }.include?(true)
  end
end

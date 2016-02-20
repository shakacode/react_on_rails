json.array!(@<%= plural_table_name %>) do |<%= singular_table_name %>|
  json.extract! <%= singular_table_name %>, <%= attributes_list %>
  json.url <%= singular_table_name %>_url(<%= singular_table_name %>, format: :json)
end

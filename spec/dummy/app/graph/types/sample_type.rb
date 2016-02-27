SampleType = GraphQL::ObjectType.define do
  name "Sample"
  description "Sample"
  interfaces [NodeIdentification.interface]
  global_id_field :id
  field :name, !types.String, "Sample name"
end

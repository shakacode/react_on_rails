QueryType = GraphQL::ObjectType.define do
  name "Query"
  description "The query root of this schema. See available queries."

  # Used by Relay to lookup objects by UUID: /TO BE discussed
  field :node, field: NodeIdentification.field

  # Hack until relay has lookup for root fields
  field :root, SampleType do
    description 'Root object to get viewer related collections'
    resolve -> (obj, args, ctx) { Hashie::Mash.new({ id: rand(1000), name: 'Sample' }) }
  end

end

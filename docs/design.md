```ruby
class MyStruct < Crazytown::StructBase
  attribute :b, Struct do
    default { x: 1, y: 2 }
    attributes = {
      x: Attribute.new :x, Type.new(default: 10)
      y: Attribute.new :y, Type.new(default: 20)
    }
  end

  attributes[:b] = Attribute.new(name: :b, )
end
class ChildStruct < MyStruct
  attributes[:a] = attributes[:a].specialize_raw(default: { x: 3, z: 4 })
end
```

Type::TypeClass
Type::TypeModule

Value
|-- Array
|-- Hash
|-- Set
|-- Struct
|   |-- Type
|   |   |-- ArrayType
|   |   |   |-- PathArrayType
|   |   |-- HashType
|   |   |-- PathType
|   |   |-- SetType
|   |   |-- StructType
|   |   |-- SymbolType
|   |   |-- UnionType
|   |   |   |-- JSONValueType
|-- ValueClass
|   |-- ArrayClass                          <::Array +Array
|   |-- HashClass                           <::Hash  +Hash
|   |-- SetClass                            <::Set   +Set
|   |-- StructClass                         +StructBase .+StructType

Accessor                                    +StructBase .+StructType
|-- StructAttribute                                     .+StructType
|-- ArrayElement                                        .+StructType
|-- HashValue                                           .+StructType
|-- SetItem                                             .+StructType
|-- ParsedValue                                         .+StructType

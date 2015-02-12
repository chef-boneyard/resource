
Strong typing
2. Coercion

```ruby
class MyStruct < Crazytown::StructBase
  property :b, Struct do
    default { x: 1, y: 2 }
    propertys = {
      x: property.new :x, Type.new(default: 10)
      y: property.new :y, Type.new(default: 20)
    }
  end

  propertys[:b] = property.new(name: :b, )
end
class ChildStruct < MyStruct
  propertys[:a] = propertys[:a].specialize_raw(default: { x: 3, z: 4 })
end
```

Types::TypeClass
Types::TypeModule

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
|-- Structproperty                                     .+StructType
|-- ArrayElement                                        .+StructType
|-- HashValue                                           .+StructType
|-- SetItem                                             .+StructType
|-- ParsedValue                                         .+StructType

module Yaks
  class Mapper
    class Form
      extend Util::Deprecated
      include Attributes.new(name: nil, action: nil, title: nil, method: nil, media_type: nil, fields: [])

      deprecated_alias :href, :action

      Builder = StatefulBuilder.new(self) do
        def_set :name, :action, :title, :method, :media_type
        def_add :field, create: Field::Builder, append_to: :fields
        HTML5Forms::INPUT_TYPES.each do |type|
          def_add type, create: Field::Builder, append_to: :fields, defaults: { type: type }
        end
      end

      def self.create(name = nil, options = {}, &block)
        Builder.build(new({name: name}.merge(options)), &block)
      end

      def add_to_resource(resource, mapper, _context)
        resource.add_form(to_resource(mapper))
      end

      def to_resource(mapper)
        attrs = {
          fields: resource_fields(mapper),
          action: mapper.expand_uri(action, true)
        }
        [:name, :title, :method, :media_type].each do |attr|
          attrs[attr] = mapper.expand_value(public_send(attr))
        end
        Resource::Form.new(attrs)
      end

      def resource_fields(mapper)
        fields.map { |field| field.to_resource(mapper) }
      end

    end
  end
end

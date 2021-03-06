require 'spec_helper'

RSpec.describe Yaks::Runner do
  subject(:runner) {
    described_class.new(object: object, config: config, options: options)
  }

  let(:object) { Object.new }
  let(:config) { Yaks::Config.new }
  let(:options) { {} }

  describe '#call' do
    let(:runner) {
      Class.new(described_class) do
        def steps
          [ [:step1, proc { |x| x + 35      }],
            [:step2, proc { |x| "#{x} #{x}" }] ]
        end
      end.new(object: object, config: config, options: options)
    }

    let(:object) { 7 }

    it 'should go through all the steps' do
      expect(runner.call).to eql "42 42"
    end
  end

  describe '#context' do
    it 'should contain the policy, env, and an empty mapper_stack' do
      expect(runner.context).to eql(policy: config.policy, env: {}, mapper_stack: [])
    end

    context 'with an item mapper' do
      let(:options) { { item_mapper: :foo } }

      it 'should contain the item_mapper' do
        expect(runner.context).to eql(policy: config.policy, env: {}, mapper_stack: [], item_mapper: :foo)
      end
    end
  end

  describe '#format_class' do
    let(:config) do
      Yaks::Config.new do
        default_format :collection_json
      end
    end

    let(:rack_env) {
      { 'HTTP_ACCEPT' => 'application/hal+json;q=0.8, application/vnd.api+json' }
    }

    it 'should fall back to the default when no HTTP_ACCEPT key is present' do
      runner = described_class.new(object: nil, config: config, options: { env: {} })
      expect(runner.format_class).to equal Yaks::Format::CollectionJson
    end

    it 'should detect format based on accept header' do
      rack_env = { 'HTTP_ACCEPT' => 'application/hal+json;q=0.8, application/vnd.api+json' }
      runner = described_class.new(object: nil, config: config, options: { env: rack_env })
      expect(runner.format_class).to equal Yaks::Format::JsonAPI
    end

    it 'should know to pick the best match' do
      rack_env = { 'HTTP_ACCEPT' => 'application/hal+json;q=0.8, application/vnd.api+json;q=0.7' }
      runner = described_class.new(object: nil, config: config, options: { env: rack_env })
      expect(runner.format_class).to equal Yaks::Format::Hal
    end

    it 'should pick the one given in the options if no header matches' do
      rack_env = { 'HTTP_ACCEPT' => 'text/xml, application/json' }
      runner = described_class.new(object: nil, config: config, options: { format: :hal, env: rack_env })
      expect(runner.format_class).to equal Yaks::Format::Hal
    end

    it 'should fall back to the default when no mime type is recognized' do
      rack_env = { 'HTTP_ACCEPT' => 'text/xml, application/json' }
      runner = described_class.new(object: nil, config: config, options: { env: rack_env })
      expect(runner.format_class).to equal Yaks::Format::CollectionJson
    end
  end

  describe '#format_name' do
    context 'with no format specified' do
      it 'should default to :hal' do
        expect(runner.format_name).to eql :hal
      end
    end

    context 'with a default format specified' do
      let(:config) { Yaks::Config.new { default_format :collection_json } }

      context 'with a format in the options' do
        let(:options) { { format: :json_api } }
        it 'should give preference to that one' do
          expect(runner.format_name).to eql :json_api
        end
      end

      context 'without a format in the options' do
        it 'should take the specified default' do
          expect(runner.format_name).to eql :collection_json
        end
      end
    end
  end

  describe '#formatter' do
    let(:config) {
      Yaks::Config.new do
        default_format :json_api
        format_options :json_api, {format_option: [:foo]}
      end
    }

    let(:formatter) { runner.formatter }

    it 'should create a formatter based on class and options' do
      expect(formatter).to be_a Yaks::Format::JsonAPI
      expect(formatter.send(:options)).to eql(format_option: [:foo])
    end
  end

  describe '#insert_hooks' do
    let(:options) { { mapper: Yaks::Mapper } }
      let(:config) { Yaks::Config.new(&hooks) }

    describe 'before' do
      let(:hooks) { proc { before(:map) { :before_map_impl } } }

      it 'should insert a hook before the step' do
        expect(runner.steps.map(&:first)).to eql [
          :before_map, :map, :format, :primitivize, :serialize
        ]
        expect(runner.steps.assoc(:before_map).last.call).to be :before_map_impl
      end
    end

    describe 'after' do
      let(:hooks) { proc { after(:format) { :after_format_impl } } }

      it 'should insert a hook after the step' do
        expect(runner.steps.map(&:first)).to eql [
          :map, :format, :after_format, :primitivize, :serialize
        ]
        expect(runner.steps.assoc(:after_format).last.call).to be :after_format_impl
      end
    end

    describe 'around' do
      let(:hooks) { proc { around(:format) { :around_format_impl } } }

      it 'should insert a hook around the step' do
        expect(runner.steps.map(&:first)).to eql [
          :map, :format, :primitivize, :serialize
        ]
        expect(runner.steps.assoc(:format).last.call(nil, nil)).to be :around_format_impl
      end
    end

    describe 'around' do
      let(:hooks) { proc { skip(:serialize) } }

      it 'should insert a hook before the step' do
        expect(runner.steps.map(&:first)).to eql [
          :map, :format, :primitivize
        ]
      end
    end

    describe 'multiple hooks' do
      let(:hooks) {
        proc {
          after(:format) { :after_format_impl }
          skip(:serialize)
        }
      }

      it 'should insert the hooks' do
        expect(runner.steps.map(&:first)).to eql [
          :map, :format, :after_format, :primitivize
        ]
      end
    end
  end

  describe '#mapper' do
    context 'with an explicit mapper in the options' do
      let(:mapper_class) { Class.new(Yaks::Mapper) }
      let(:options) { { mapper: mapper_class } }

      it 'should take the mapper from options' do
        expect(runner.mapper).to be_a mapper_class
      end
    end

    context 'without a mapper specified' do
      let(:object) { Pet.new(id: 7, name: 'fifi', species: 'cat') }

      it 'should infer one from the object to be mapped' do
        expect(runner.mapper).to be_a PetMapper
      end

      it 'should pass the context to the mapper' do
        expect(runner.mapper.context).to be runner.context
      end
    end
  end

  describe '#serializer' do
    context 'with a serializer configured' do
      let(:config) {
        Yaks::Config.new do
          json_serializer do |input|
            "serialized #{input}"
          end
        end
      }

      it 'should try to find an explicitly configured serializer' do
        expect(runner.serializer.call('42', {})).to eql 'serialized 42'
      end
    end

    it 'should fall back to the policy' do
      expect(runner.serializer.call([1,2,3], {})).to eql "[\n  1,\n  2,\n  3\n]"
    end
  end

  describe '#steps' do
    let(:options) {{ mapper: Yaks::Mapper }}

    it 'should have all four steps' do
      expect(runner.steps).to eql [
        [ :map, runner.mapper ],
        [ :format, runner.formatter ],
        [ :primitivize, runner.primitivizer],
        [ :serialize, runner.serializer ]
      ]
    end

    context 'with hooks' do
      let(:config) {
        Yaks::Config.new do
          after(:format, :my_hook) { :foo }
        end
      }

      it 'should insert hooks' do
        expect(runner.steps.map(&:first)).to eql [:map, :format, :my_hook, :primitivize, :serialize]
      end
    end
  end

  describe '#primitivizer' do
    describe 'with a non json based format' do
      let(:config) do
        Yaks::Config.new do
          default_format :html
        end
      end

      it 'should return the identity function' do
        expect(runner.primitivizer.call(:foo)).to eql :foo
      end
    end

    describe 'with a json based format' do
      it 'should return the primitivizer' do
        expect(runner.primitivizer.call(:foo)).to eql "foo"
      end
    end
  end

  it 'should memoize' do
    expect(runner.formatter).to be runner.formatter
  end

end

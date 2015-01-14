RSpec.describe Yaks::Resource do
  subject(:resource) { described_class.new(init_opts) }
  let(:init_opts) { {} }

  context 'with a zero-arg constructor' do
    subject(:resource) { described_class.new }

    its(:type)           { should be_nil }
    its(:attributes)     { should eql({}) }
    its(:links)          { should eql [] }
    its(:subresources)   { should eql [] }
    its(:self_link)      { should be_nil }
    its(:null_resource?) { should be false }
    its(:collection?)    { should be false }
  end

  context 'with a type' do
    let(:init_opts) { { type: 'post' } }
    its(:type) { should eql 'post' }
  end

  context 'with attributes' do
    let(:init_opts) { { attributes: {name: 'Arne', age: 31} } }

    it 'should delegate [] to attribute access' do
      expect(resource[:name]).to eql 'Arne'
    end
  end

  context 'with links' do
    let(:init_opts) {
      {
        links: [
          Yaks::Resource::Link.new(rel: :profile, uri: '/foo/bar/profile'),
          Yaks::Resource::Link.new(rel: :self, uri: '/foo/bar')
        ]
      }
    }
    its(:links) { should eql [
        Yaks::Resource::Link.new(rel: :profile, uri: '/foo/bar/profile'),
        Yaks::Resource::Link.new(rel: :self, uri: '/foo/bar')
      ]
    }

    its(:self_link) { should eql Yaks::Resource::Link.new(rel: :self, uri: '/foo/bar') }
  end

  context 'with subresources' do
    let(:init_opts) { { subresources: [ Yaks::Resource.new(type: 'comment', rels: ['comments']) ] } }
    its(:subresources) { should eql [Yaks::Resource.new(type: 'comment', rels: ['comments'])]  }

    it 'should return an enumerable for #seq' do
      expect(resource.seq.each.with_index.to_a).to eq  [ [resource, 0] ]
    end
  end

  it 'should act as a collection of one' do
    expect(resource.seq.each.to_a).to eql [resource]
  end

  describe 'persistent updates' do
    let(:resource) {
      Yaks::Resource.new(
        attributes: {x: :y},
        links: [:one],
        subresources: [ :subres ]
      )
    }

    it 'should do updates without modifying the original' do
      expect(
        resource
          .merge_attributes(foo: :bar)
          .add_link(:a_link)
          .add_subresource(:a_subresource)
          .merge_attributes(foo: :baz)
      ).to eq Yaks::Resource.new(
        attributes: {x: :y, foo: :baz},
        links: [:one, :a_link],
        subresources: [:subres, :a_subresource]
      )

      expect(resource).to eq Yaks::Resource.new(
        attributes: {x: :y},
        links: [:one],
        subresources: [:subres]
      )
    end
  end

  describe '#initialize' do
    it 'should verify subresources is an array' do
      expect { Yaks::Resource.new(subresources: { '/rel/comments' => []}) }
        .to raise_exception /comments/
    end

    it 'should verify subresources is an array' do
      expect { Yaks::Resource.new(subresources: []) }
        .to_not raise_exception
    end

    it 'should work without args' do
      expect( Yaks::Resource.new ).to be_a Yaks::Resource
    end

    it 'should take defaults when no args are passed' do
      expect( Yaks::Resource.new.rels ).to eq []
    end
  end

  describe '#self_link' do
    let(:init_opts) {
      { links:
        [
          Yaks::Resource::Link.new(rel: :self, uri: 'foo'),
          Yaks::Resource::Link.new(rel: :self, uri: 'bar'),
          Yaks::Resource::Link.new(rel: :profile, uri: 'baz')
        ]
      }
    }
    it 'should return the last self link' do
      expect(resource.self_link).to eql Yaks::Resource::Link.new(rel: :self, uri: 'bar')
    end
  end

  describe '#add_rel' do
    it 'should add to the rels' do
      expect(resource.add_rel(:foo).add_rel(:bar))
        .to eql Yaks::Resource.new(rels: [:foo, :bar])
    end
  end

  describe '#add_form' do
    it 'should append to the forms' do
      expect(resource.add_form(Yaks::Resource::Form.new(name: :a_form)))
        .to eq Yaks::Resource.new(forms: [Yaks::Resource::Form.new(name: :a_form)])
    end
  end

  describe '#find_form' do
    it 'should find a form by name' do
      expect(resource
              .add_form(Yaks::Resource::Form.new(name: :a_form))
              .add_form(Yaks::Resource::Form.new(name: :b_form))
              .find_form(:b_form))
        .to eq Yaks::Resource::Form.new(name: :b_form)
    end
  end

  describe '#members' do
    it 'should raise unsupported operation error' do
      expect { resource.members }.to raise_error(
        Yaks::UnsupportedOperationError, "Only Yaks::CollectionResource has members"
      )
    end
  end

  describe '#with_collection' do
    it 'should be a no-op' do
      expect(Yaks::Resource.new.with_collection([:foo])).to eql Yaks::Resource.new
    end
  end

end

require 'spec_helper'

RSpec.describe Yaks::NullResource do
  subject(:null_resource) { described_class.new }

  its(:attributes)     { should eq({}) }
  its(:links)          { should eq [] }
  its(:subresources)   { should eq [] }
  its(:collection?)    { should be false }
  its(:null_resource?) { should be true }

  it { should respond_to :[] }

  its(:type) { should be_nil }

  describe '#each' do
    its(:each)         { should be_a Enumerator }

    it 'should not yield anything' do
      null_resource.each { fail }
    end
  end

  it 'should contain nothing' do
    expect( null_resource[:key] ).to be_nil
  end

  context 'when a collection' do
    subject(:null_resource) { described_class.new( collection: true ) }
    its(:collection?) { should be true }
  end

  it 'should not allow updating attributes' do
    expect { null_resource.update_attributes({}) }.to raise_error(
      Yaks::UnsupportedOperationError, "Operation update_attributes not supported on Yaks::NullResource"
    )
  end

  it 'should not allow adding links' do
    expect { null_resource.add_link(nil) }.to raise_error(
      Yaks::UnsupportedOperationError, "Operation add_link not supported on Yaks::NullResource"
    )
  end

  it 'should not allow adding forms' do
    expect { null_resource.add_form(nil) }.to raise_error(
      Yaks::UnsupportedOperationError, "Operation add_form not supported on Yaks::NullResource"
    )
  end

  it 'should not allow adding subresources' do
    expect { null_resource.add_subresource(nil) }.to raise_error(
      Yaks::UnsupportedOperationError, "Operation add_subresource not supported on Yaks::NullResource"
    )
  end
end

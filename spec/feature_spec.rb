require 'spec_helper'

describe 'pd-feature-test::simple' do
  subject do
    ChefSpec::SoloRunner.new.converge(described_recipe)
  end

  it 'creates a resource for an enabled feature' do
    expect(subject).to create_file('affirmative')
  end

  it 'creates a resource for a disabled feature' do
    expect(subject).to create_file('negative')
  end
end

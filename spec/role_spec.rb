require 'spec_helper'

describe 'pd-feature-test::role' do
  subject do
    ChefSpec::SoloRunner.new do |node|
      node.name 'node1'
      node.chef_environment '_default'
    end.converge('role[app]')
  end

  before do
    stub_search('node', 'chef_environment:_default AND roles:app').and_return((1..3).map { |i| Chef::Node.build("node#{i}") })
  end

  it 'enables the feature for the first app node' do
    expect(subject).to create_file('role')
  end

  context 'for the second app node' do
    subject do
      ChefSpec::SoloRunner.new do |node|
        node.name 'node2'
      end.converge('role[app]')
    end

    it 'does not enable the feature' do
      expect(subject).to_not create_file('count')
    end
  end

  context 'for a node with a different role' do
    subject do
      ChefSpec::SoloRunner.new do |node|
        node.name 'node1'
      end.converge('role[foo]')
    end

    it 'does not enable the feature' do
      expect(subject).to_not create_file('count')
    end
  end

  context 'for a node with a role for which no attribute is explicitly set' do
    subject do
      ChefSpec::SoloRunner.new do |node|
        node.name 'node1'
      end.converge('role[bar]')
    end

    it 'does not enable the feature' do
      expect(subject).to_not create_file('count')
    end
  end
end

require 'spec_helper'

describe 'pd-feature-test::rules' do
  subject do
    ChefSpec::SoloRunner.new do |node|
      node.name 'node1'
      node.chef_environment '_default'
    end.converge(described_recipe)
  end

  before do
    stub_search('node', 'chef_environment:_default').and_return((1..3).map { |i| Chef::Node.build("node#{i}") })
  end

  it 'selects the first node to participate in both groups' do
    expect(subject).to create_file('count')
    expect(subject).to create_file('percent')
  end

  context 'for node 2 of 3' do
    subject do
      ChefSpec::SoloRunner.new do |node|
        node.name 'node2'
        node.chef_environment '_default'
      end.converge(described_recipe)
    end

    it 'selects the node to participate in count group only' do
      expect(subject).to create_file('count')
      expect(subject).to_not create_file('percent')
    end
  end

  context 'for node 3 of 3' do
    subject do
      ChefSpec::SoloRunner.new do |node|
        node.name 'node3'
        node.chef_environment '_default'
      end.converge(described_recipe)
    end

    it 'selects the node to participate in neither group' do
      expect(subject).to_not create_file('count')
      expect(subject).to_not create_file('percent')
    end
  end
end

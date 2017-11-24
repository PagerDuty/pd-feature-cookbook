require 'spec_helper'
require_relative '../libraries/feature'

describe 'pd-feature-test::invalid_attr_value' do
  subject do
    ChefSpec::SoloRunner.new.converge(described_recipe)
  end

  it 'complains about a bad attribute type' do
    expect { subject }.to raise_error(PagerDuty::Feature::FeatureCheckError, /is not a valid attribute type for a feature: only boolean or string are allowed/)
  end
end

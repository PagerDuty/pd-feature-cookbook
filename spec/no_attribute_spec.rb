require 'spec_helper'
require_relative '../libraries/feature'

describe 'pd-feature-test::no_attr' do
  subject do
    ChefSpec::SoloRunner.new.converge(described_recipe)
  end

  it 'complains about a missing attribute' do
    expect { subject }.to raise_error(PagerDuty::Feature::FeatureCheckError, 'No attribute is defined for feature flag \'no_attribute\' in cookbook \'pd-feature-test\'')
  end
end

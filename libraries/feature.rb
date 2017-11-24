# Copyright 2017 by PagerDuty, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module PagerDuty
  module Feature
    class FeatureCheckError < StandardError
    end

    def feature_enabled?(name, search_scope: nil)
      feature_check(feature_check_context(name, search_scope))
    rescue FeatureCheckError => e
      raise FeatureCheckError, e.message + " for feature flag '#{name}' in cookbook '#{cookbook_name}'"
    end

    private

    # This is a separate function because it can be recursively called by evaluate_role()
    def feature_check(context)
      attribute_name = "feature_#{context[:name]}"

      # When doing a role-specific check, this error will not be raised because if many roles are
      # applied to a node this would require an attribute to be defined for each role.
      raise(FeatureCheckError, 'No attribute is defined') unless (node.attribute?(cookbook_name) && node[cookbook_name].attribute?(attribute_name)) || context[:role]
      ruleset = node[cookbook_name][attribute_name]

      case ruleset
      when TrueClass, FalseClass
        Chef::Log.debug("Feature check: '#{context[:name]}' is #{feature_translate(ruleset)} by attribute")
        ruleset
      when String
        evaluate_ruleset(context, ruleset)
      when nil
        false
      else
        raise(FeatureCheckError, "#{ruleset.class} is not a valid attribute type for a feature: only boolean or string are allowed")
      end
    end

    def evaluate_ruleset(context, ruleset)
      ruleset.split(',').each do |rule|
        key, arg = rule.split(':')

        method_name = "evaluate_#{key}"
        raise(FeatureCheckError, "Rule '#{key}' is not supported") unless respond_to?(method_name, true)
        if send(method_name, context, arg)
          Chef::Log.debug("Feature check: '#{context[:name]}' is enabled by rule '#{rule}'")
          return true
        end
      end
      Chef::Log.debug("Feature check: '#{context[:name]}' is disabled, did not match any rules")
      false
    end

    def evaluate_count(context, arg)
      count = arg.to_i

      result = stable_scoped_search(context[:search])
      Chef::Log.debug("Feature check: this node's position for feature '#{context[:name]}' is #{result.index(node.name) + 1} out of #{result.length}")
      result.first(count).include? node.name
    end

    def evaluate_percent(context, arg)
      percent = arg.to_f

      result = stable_scoped_search(context[:search])
      count = (result.length * percent / 100).floor
      Chef::Log.debug("Feature check: this node's percentage position for feature '#{context[:name]}' is #{format('%.1f', (result.index(node.name) + 1.0) / result.length * 100.0)}")
      result.first(count).include? node.name
    end

    def evaluate_role(context, arg)
      raise(FeatureCheckError, 'The \'role\' rule does not accept arguments') if arg

      node['roles'].each do |role|
        nested_context = {
          search: "#{context[:search]} AND roles:#{role}",
          name: "#{context[:name]}_#{role}",
          role: role,
        }
        if feature_check(nested_context)
          Chef::Log.debug("Feature check: '#{context[:name]}' is enabled by role '#{role}'")
          return true
        end
      end
      false
    end

    def feature_check_context(name, search_scope)
      {
        search: search_scope || "chef_environment:#{node.chef_environment}",
        name: name,
        role: nil,
      }
    end

    def stable_scoped_search(scope)
      Chef::Log.debug("Feature check: performing scoped search '#{scope}'")
      search(:node, scope, filter_result: { 'name' => ['name'] }).map(&:name).sort
    end

    def feature_translate(boolean)
      case boolean
      when true
        'enabled'
      when false
        'disabled'
      else
        raise
      end
    end
  end
end

Chef::Recipe.send(:include, PagerDuty::Feature)

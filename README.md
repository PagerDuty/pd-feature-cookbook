# pd-feature Cookbook

This is a library cookbook that adds support for rule-based feature flags to Chef recipes. The primary use case is designating a particular number or percentage of machines in a Chef environment to receive a new feature without having to modify individual nodes with tagging or manual editing. This is useful for canaries and gradual rollouts of new features.

## Requirements

### Chef

- Chef 12.1+

## Usage

There is a test cookbook under `test/pd-feature-test` that contains examples for all supported rules.

To use the library, add this cookbook to your `metadata.rb`:

```ruby
depends 'pd-feature'
```

Then implement features in your recipes, using `feature_enabled?` to check the feature flag, like so:

```ruby
if feature_enabled?('name_of_feature')
  new_hotness
else
  old_code
end
```

Finally, write the feature flag rules. The rules are stored as Chef attributes. For a cookbook named 'foo' and a feature named 'bar', the attribute should be named like this:

```ruby
default['foo']['feature_bar'] = false
```

The simplest rules are `true` (feature is always enabled) and `false` (feature is always disabled). Note that they are not strings.

### Count rule

```ruby
default['foo']['feature_bar'] = 'count:3'
```

In this example, the feature is enabled for the first 3 machines in every Chef environment the recipe runs. Namely, if you have two Chef environments, `alpha` and `bravo` with 5 machines each, the feature will be enabled on 6 machines, 3 in `alpha` and 3 in `bravo`.

### Percent rule

```ruby
default['foo']['feature_bar'] = 'percent:51'
```

In this example, the feature is enabled for half the machines in every Chef environment the recipe runs. Namely, if you have two Chef environments, `alpha` and `bravo` with 2 and 4 machines respectively, the feature will be enabled on 3 machines, 1 in `alpha` and 2 in `bravo`.

Percentages are interpreted as floats, so using a slightly bigger value avoids float comparison issues with small number of machines: use `34` for one third, for example. The number of machines chosen is rounded down, so in a small enough environment and percentage you could end up with no machines chosen (for example, 5 machines and `percent:10`).

### Role-specific rule

```ruby
default['foo']['feature_bar'] = 'role'
default['foo']['feature_bar_app'] = 'count:2'
```

In this example, the feature is enabled for the first two machines in a Chef environment the recipe runs that have the Chef role `app`. We are using expanded matching, which means you can match on either a role specified in the node run-list or a role that is included by a role or recipe but not explicitly named in the node's run-list.

Note that when the recipe containing the feature is already role-specific, you do not need this rule; this is for the rare case when the recipe is shared across multiple roles and you want to enable the feature on a particular role in a specific Chef environment.

### Sort order

What does it mean "the first X machines" or "the first Y percent"? The implementation guarantees the order is stable (successive Chef runs will select the same machines), but the specific order is an implementation detail and might change. Currently an alphabetical sort by node name is used.

### Multiple rules

Rules can be combined:

```ruby
default['foo']['feature_bar'] = 'count:1,percent:26'
```

means at least one node will be chosen, and in large environments about a quarter of nodes will be chosen. The operator is "OR" and the first match that enables the feature stops the evaluation.

You cannot have a simple rule (`true` or `false`) in a combination, because it is pointless: `false` is implied (feature is disabled if it is not enabled by any rule), and `true` would always enable the feature, rendering the rest of the clauses unnecessary.

### Custom scope

By default, all rules are evaluated in the context of the Chef environment a node is located in. You can specify any other context using the optional `search_scope` parameter. It will replace the environment-specific search. This can be used select more complicated subsets of nodes or to apply a feature to the entire infrastructure with a global search like `node:*`.

```ruby
if feature_enabled?('name_of_feature', search_scope: 'cloud_provider:ec2')
  aws_specific_new_hotness
end
```

### Debugging

The cookbook outputs a bunch of information on the `DEBUG` log level to help you understand which features are enabled and why. Here are a few examples:

```
DEBUG: Feature check: 'simple' is enabled by attribute
DEBUG: Feature check: this node's position for feature 'foo' is 2 out of 3
DEBUG: Feature check: 'bar' is enabled by rule 'percent:34'
```

Note that this logic normally runs during Chef's compile phase, and resources run during the converge phase, so the debugging output might be located a long distance away from the output from the resources the feature controls.

## Contributing

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change
5. Run the tests, ensuring they all pass. Run `cookstyle`. Run `foodcritic`.
6. Submit a Pull Request using Github

## License and Authors

Author: Max Timchenko ([@maxvt](https://twitter.com/MaxVT))

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```


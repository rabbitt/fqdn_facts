# FqdnFacts

FqdnFacts allows you to create fact handlers for different FQDN formats. This is primarily intended for use with Puppet/Facter to facilitate dynamic fact generation based on FQDNs.

## Installation

Add this line to your application's Gemfile:

    gem 'fqdn_facts'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fqdn_facts

## Usage

An example is (hopefully) worth a thousand words:

```ruby
require 'facter'
require 'fqdn_facts'

FqdnFacts.register(:baseline) do
  priority 10
  
  # this defines the order of the components
  components :host, :sub, :tld

  # if a component is not listed in 'components' it is
  # assumed that the validation for it is :any. However,
  # all sub-components /must/ have a validation defined.
  component :host, { 
    # order of sub-components is important!
    type:    %r'^([a-z][a-z-]*[a-z])', 
    id:      %r'(\d{2,})', 
    subtype: %r'([ms]?)'
  }
  component :sub, /.+/
  component :tld, 'bar.com'

  # conversions happen during fact retrieval and
  # prior to dynamic fact generation.
  convert :host, {
    subtype: ->(v) { v == 'm' ? 'master' : 'slave' },
    id: ->(v) { v.to_i }
  }

  # facts generated dynamically using procs/lambdas 
  # are calculated after all conversions, and in 
  # order of assignment. If you use a lambda/proc, it will
  # is expected to receive at most 1 parameter. If you receive
  # for one, then that parameter will contain the list of facts
  # generated up until that point. 
  add_fact :hostname, ->(f) { f[:host] }
  add_fact :domain, ->(f) { [f[:sub], f[:tld]].join('.') }
end # this essentially matches ([a-z][a-z-]*[a-z])(\d{2,})([ms]?)\.([^\.]+)\.bar\.com

# copy baseline to create the qa handler. This means
# that the :qa handler will contain all the settings
# that we defined in :baseline aside from any settings
# that we override in :qa.
FqdnFacts.register(:qa, copy: :baseline) do
  component :sub, %r:qa\d*:
  add_fact :env, 'qa'
end # this matches ([a-z][a-z-]*[a-z])(\d{2,})([ms]?)\.qa\d+\.bar\.com

# let's say you don't have a server that conforms to your previously
# defined :host component (e.g., it doesn't use id/subtype), but is instead
# a static value.
FqdnFacts.register(:qa_foo_server, :baseline) do
  component :host, 'foo-server'
end # this matches foo-server\.qa\d+\.bar\.com

# Now we gather our facts:
begin
  facts = FqdnFacts.handler(Facter['fqdn'].value).retrieve_facts
  facts.each do |fact, value|
    Facter.add(fact) { setcode { value } }
  end
rescue FqdnFacts::UnresolveableHandler, e
  puts e.message
end
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/fqdn_facts/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

# FqdnFacts

FqdnFacts allows you to create fact handlers for different FQDN formats. This is primarily intended for use with Puppet/Facter to facilitate dynamic fact generation based on FQDNs.

## Status

<img src="https://travis-ci.org/rabbitt/fqdn_facts.svg?branch=master" />

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

%w[
  facter 
  fqdn_facts 
  awesome_print
].each do |lib|
  begin
    require lib
  rescue LoadError
    puts "Unable to find lib '#{lib}' - try installing it: gem install #{lib}"
    exit 1
  end
end

# setup a baseline handler that we can use as a "catch-all"
# as well as a foundation to derive from with other handlers.
FqdnFacts.register(:baseline) do
  priority 1000 # we want this to be used last as a catch-all

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
  component :tld, /.+/

  # conversions happen during fact retrieval and
  # prior to dynamic fact generation.
  convert :host, {
    subtype: ->(v) {
      case v
        when 'm' then 'master'
        when 's' then 'slave'
      end
    },
    id: ->(v) { v.to_i }
  }

  # facts generated dynamically using procs/lambdas are calculated
  # after all conversions, and in order order of assignment. If you
  # use a lambda/proc, it is expected to receive at most one parameter.
  # If you receive for one, then that parameter will contain a hash of
  # facts generated up until that point.
  add_fact :hostname, ->(f) { f[:host] }
  add_fact :domain, ->(f) { [f[:sub], f[:tld]].join('.') }
end # this essentially matches ([a-z][a-z-]*[a-z])(\d{2,})([ms]?)\.([^\.]+)\.bar\.com

# copy baseline to create the qa handler. This means
# that the :qa handler will contain all the settings
# that we defined in :baseline aside from any settings
# that we override in :qa.
FqdnFacts.register(:qa, copy: :baseline) do
  priority 10
  component :sub, %r:qa\d*:
  add_fact :env, 'qa'
end # this matches ([a-z][a-z-]*[a-z])(\d{2,})([ms]?)\.qa\d+\.bar\.com

# let's say you don't have a server that conforms to your previously
# defined :host component (e.g., it doesn't use id/subtype), but is instead
# a static value.
FqdnFacts.register(:qa_foo_server, copy: :baseline) do
  # we can set this to the same priority as the :qa handler because
  # the :qa handler will fail on the :host component for foo-server
  # which will allow this handler to pick it up.
  priority 10
  component :host, 'foo-server'
  add_fact :nifty, 'data'
end # this matches foo-server\.qa\d+\.bar\.com

# Now we gather our facts:
begin
  facts = FqdnFacts.handler(ARGV.first || Facter['fqdn'].value).retrieve_facts
  facts.each do |fact, value|
    Facter.add(fact) { setcode { value } }
  end
  ap facts
rescue FqdnFacts::Error::UnresolveableHandler => e
  puts e.message
end

=begin

Now given a FQDN of foo-server.qa3.bar.com, we would get the following facts:

{
  :fqdn         => "foo-server.qa3.bar.com",
  :handler_name => "qa_foo_server",
  :hostname     => "foo-server",
  :domain       => "qa3.bar.com",
  :nifty        => "data",
  :host         => "foo-server",
  :sub          => "qa3",
  :tld          => "bar.com"
}

And, for foobaz01.qa1.bar.com:

{
  :fqdn         => "foobaz01.qa1.bar.com",
  :handler_name => "qa",
  :hostname     => "foobaz01",
  :domain       => "qa1.bar.com",
  :env          => "qa",
  :host         => "foobaz01",
  :sub          => "qa1",
  :tld          => "bar.com",
  :host_type    => "foobaz",
  :host_id      => 1
}

And, now one that baseline should catch, www01.abc.com:

{
  :fqdn         => "www01.abc.com",
  :handler_name => "baseline",
  :hostname     => "www01",
  :domain       => "abc.com",
  :host         => "www01",
  :sub          => "abc",
  :tld          => "com",
  :host_type    => "www",
  :host_id      => 1
}
=end
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/fqdn_facts/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

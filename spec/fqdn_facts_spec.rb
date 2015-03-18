require 'spec_helper'

describe FqdnFacts do
  before :all do
    FqdnFacts.register(:baseline) do
      priority 10

      components :host, :sub, :tld

      component :host, {
        type:    %r'^([^\d]+)',
        id:      %r'(\d+)',
        subtype: %r'([ms]?)'
      }
      component :tld, 'example.com'

      convert :host, {
        subtype: ->(v) { v == 'm' ? 'master' : 'slave' },
        id: ->(v) { v.to_i }
      }

      add_fact :hostname, ->(f) { f[:host] }
      add_fact :domain, ->(f) { [f[:sub], f[:tld]].join('.') }
    end
  end

  it 'has a version number' do
    expect(FqdnFacts::VERSION).not_to be nil
  end

  it 'registers a handler named baseline' do
    expect(FqdnFacts.registry).to include(:baseline)
  end

  context 'with fqdn "foo01m.bar.example.com"' do
    before do
      @fqdn     = 'foo01m.bar.example.com'
      @handler  = FqdnFacts.handler(@fqdn)
    end

    it 'returns a valid hash' do
      expect(@handler.retrieve_facts).to be_a Hash
    end

    describe 'facts' do
      let(:facts) { @handler.retrieve_facts }
      {
        :host => 'foo01m',
        :host_type => 'foo',
        :host_id   => 1,
        :host_subtype => 'master',
        :hostname => 'foo01m',
        :sub => 'bar',
        :domain => 'bar.example.com',
        :fqdn => 'foo01m.bar.example.com',
        :handler_name => 'baseline'
      }.each do |key, value|
        it "sets #{key.inspect} to #{value.inspect}" do
          expect(facts).to include(key)
          expect(facts[key]).to eq(value)
        end
      end
    end
  end
end

=begin
    Copyright (C) 2015  Carl P. Corliss <rabbitt@gmail.com>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
=end

require "fqdn_facts/version"
require 'fqdn_facts/core_ext'

#
# Provides a DSL for generating Fact Handlers for different
# fully qualified domain names.
#
module FqdnFacts
  @registry = {}

  autoload :BaseHandler, 'fqdn_facts/base_handler'
  autoload :Error, 'fqdn_facts/errors'

  class << self
    attr_reader :registry

    # Registers a FQDN Fact Handler
    #
    # @param klass   Symbol name of handler to register
    # @param options Hash   options to pass
    # @param block   Block  block of DSL code
    #
    # @return FqdnFacts::BaseHandler derived class
    def register(klass, options = {}, &block)
      klass_const = klass.to_s.camelize
      unless BaseHandler.const_defined? klass_const
        BaseHandler.const_set(klass_const, Class.new(BaseHandler))
      end

      if other = options.delete(:copy)
        unless other = @registry[other.to_sym]
          fail Error::HandlerNotFound, other
        end
        @registry[klass.to_sym] = BaseHandler.const_get(klass_const).copy_from(other)
      else
        @registry[klass.to_sym] = BaseHandler.const_get(klass_const).new
      end


      if block.arity == 1
        yield @registry[klass.to_sym]
      else
        @registry[klass.to_sym].instance_eval(&block)
      end

      @registry[klass.to_sym]
    end

    # Retrieves a handler that is capable of generating facts
    # for the given FQDN
    #
    # @param fqdn String Fully qualified domain name to resolve into a handler
    #
    # @return FqdnFacts::BaseHandler derived class
    def handler(fqdn)
      if (handlers = @registry.values.select { |klass| klass.match?(fqdn) }).empty?
        fail Error::UnresolveableHandler, "unable to find a handler for FQDN:#{fqdn}"
      end
      handlers.sort.first.tap { |handler| handler.fqdn = fqdn }
    end
  end
end

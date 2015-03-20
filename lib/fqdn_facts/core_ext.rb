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

# @see Object
class Object
  # provides an empty? check for all objects
  # unless an object already has an empty? check
  #
  # @return [false]
  def empty?
    return false
  end

  # returns true if the object "contains" data
  # (object dependant)
  # @return [Boolean]
  def present?
    !empty?
  end

  # attempts to call a public method
  #
  # @param method <Symbol> the method to attempt to call
  # @param args [Array] optional arguments to pass to the method
  # @param block [Block] optional block to pass to the method
  #
  # @return the result of the method call, if the method exists, or nil if it doesn't
  def try(method, *args, &block)
    begin
      self.public_send(method, *args, &block)
    rescue NoMethodError
      nil
    end
  end
end

# @see NilClass
class NilClass
  # provides an empty? check for nil
  # @return true
  def empty?
    true
  end
end

# @see String
class String
  def empty?
    !!(self !~ /\S/)
  end

  # converts a camelized string to underscored
  # @return String
  def underscore
    self.split(/([A-Z][a-z0-9]+)/).reject(&:empty?).collect(&:downcase).join('_')
  end

  # converts an underscored string to a camelized one
  # @return String
  def camelize
    self.split('_').collect(&:capitalize).join
  end
end




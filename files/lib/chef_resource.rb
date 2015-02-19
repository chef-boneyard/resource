require 'chef_resource/version'
require 'chef_resource/constants'

module ChefResource
  #
  # Print a list of values with a conjunction like 'and' or 'or'
  #
  # @param conjunction [String] A word like 'and' or 'or'
  # @param separator [String] A separator like ', ' or '; '
  # @param *values A list of values to join with `to_s`
  # @return the list, joined with the separator
  # @example
  #   english_list(1, 2, 3, 4) #=> "1, 2, 3 and 4"
  def self.english_list(*values, conjunction: 'and', separator: ', ')
    case values.size
    when 0
      nil
    when 1
      values[0].to_s
    else
      "#{values[0..-2].join(separator)} #{conjunction} #{values[-1]}"
    end
  end
end

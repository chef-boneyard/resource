module ChefResource
  module CamelCase
    # foo_bar/baz_bonk -> FooBar::BazBonk
    def self.from_snake_case(snake_case)
      snake_case.to_s.split('/').map do |str|
        str.split('_').map { |s| s.capitalize }.join('')
      end.join('::')
    end

    # FooBar::BazBonk -> foo_bar/baz_bonk
    if RUBY_VERSION.to_f >= 2
      UPPERCASE_SPLIT = Regexp.new('(?=\p{Lu})')
    else
      UPPERCASE_SPLIT = Regexp.new('(?=[A-Z])')
    end

    def self.to_snake_case(camel_case)
      camel_case.to_s.split('::').map do |str|
        str.split(UPPERCASE_SPLIT).map { |s| s.downcase! }.join('_')
      end.join('/')
    end
  end
end

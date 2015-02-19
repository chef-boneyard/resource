blah_file_simple '/Users/jkeiser/x.txt' do
  content 'hi'
  mode 0777
end

# puts blah_file('/Users/jkeiser/x.txt').mode
#
# TODO this isn't working!
# blah_file '/Users/jkeiser/x.txt' do
#   mode mode | 0770
# end
#
# group 'wheel' do
#   members [ 'jkeiser']
#   members << 'jkeiser'
# end
#
# blah_file '/Users/jkeiser/x.txt' do
#   content 'hi'
#   mode 0777
# end
#
#
#
#
# ChefDSL.define :bjork, a: 'a', b: 'b' do
#   file '/Users/jkeiser/x.txt' do
#     content a
#   end
#   file '/Users/jkeiser/y.txt' do
#     content b
#   end
# end
#
# bjork do
# end

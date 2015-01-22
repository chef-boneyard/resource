blah_file_simple '/Users/jkeiser/x.txt' do
  content 'hi'
  mode 0777
end

blah_file '/Users/jkeiser/x.txt' do
  content 'hi'
  mode 0777
end

blah_file_simple '/Users/jkeiser/x.txt' do
  content 'hi'
  mode 0777
end

blah_file '/Users/jkeiser/x.txt' do
  content 'hi'
  mode 0777
end

Crazytown.define :bjork, a: 'a', b: 'b' do
  file '/Users/jkeiser/x.txt' do
    content a
  end
  file '/Users/jkeiser/y.txt' do
    content b
  end
end

bjork do
end

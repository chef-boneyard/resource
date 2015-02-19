defaults :my_file, :file, owner: 'jkeiser', group: 'staff', mode: 0755
my_file '/Users/jkeiser/x.txt' do
  content 'x'
end
my_file '/Users/jkeiser/y.txt' do
  content 'y'
end
my_file '/users/jkeiser/z.txt' do
  content 'z'
end

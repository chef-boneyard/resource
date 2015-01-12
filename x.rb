def f(x: 1, y: 2)
  puts x
  puts y
end
a = { x: 5 }
f(**a)

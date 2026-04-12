import math

#1 выражение
x = 0.1
a = 0.1
acc = 3

print(f"1 выражение:    ", math.log(1 - 2 * x * math.cos(a) + x**2))


#2 выражение
res = 0
tmp = 0

for n in range(1, acc):
    tmp = (math.cos(n * a) * x**n) / math.factorial(n)
    print(f"промежуточное {n}: ", tmp)
    res += tmp

res *= -2
print(f"2 выражение:    ", res)
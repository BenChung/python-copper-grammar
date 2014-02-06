'''Simple program to sum all integers from 1 to 1000 that are divisible by 2 and 3'''
sum = 0
for x in range(1, 1000):
    if (x % 2) == 0:
        if(x % 3) == 0:
            sum += x
print x


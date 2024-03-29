from director_exception import *
from exceptions import *

class MyFoo(Foo):
	def ping(self):
		raise NotImplementedError, "MyFoo::ping() EXCEPTION"

class MyFoo2(Foo):
	def ping(self):
		pass # error: should return a string

ok = 0

a = MyFoo()
b = launder(a)

try:
	b.pong()
except NotImplementedError, e:
	ok = 1
except:
	pass

if not ok:
	raise RuntimeError

ok = 0

a = MyFoo2()
b = launder(a)

try:
	b.pong()
except TypeError, e:
	ok = 1
except:
	pass

if not ok:
	raise RuntimeError




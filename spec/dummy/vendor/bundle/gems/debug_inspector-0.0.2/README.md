debug_inspector
===============

(C) John Mair (banisterfiend) 2012

_A Ruby wrapper for the new MRI 2.0 debug\_inspector API_

**This library only works on MRI 2.0. Requiring it on unsupported Rubies will result in a no-op**

Usage
-----

```ruby
require 'debug_inspector'

# binding of nth caller frame (returns a Binding object)
RubyVM::DebugInspector.open { |i| i.frame_binding(n) }

# iseq of nth caller frame (returns a RubyVM::InstructionSequence object)
RubyVM::DebugInspector.open { |i| i.frame_iseq(n) }

# class of nth caller frame
RubyVM::DebugInspector.open { |i| i.frame_class(n) }

# backtrace locations (returns an array of Thread::Backtrace::Location objects)
RubyVM::DebugInspector.open { |i| i.backtrace_locations }
```

Contact
-------

Problems or questions contact me at [github](http://github.com/banister)

License
-------

(The MIT License)

Copyright (c) 2012 (John Mair)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

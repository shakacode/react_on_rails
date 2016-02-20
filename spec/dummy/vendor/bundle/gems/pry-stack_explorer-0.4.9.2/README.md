pry-stack_explorer
===========

(C) John Mair (banisterfiend) 2011

_Walk the stack in a Pry session_

pry-stack_explorer is a plugin for the [Pry](http://pry.github.com)
REPL that enables the user to navigate the call-stack.

From the point a Pry session is started, the user can move up the stack
through parent frames, examine state, and even evaluate code.

Unlike `ruby-debug`, pry-stack_explorer incurs no runtime cost and
enables navigation right up the call-stack to the birth of the
program.

pry-stack_explorer is currently designed to work on **Rubinius and MRI
Ruby 1.9.2+ (including 1.9.3)**. Support for other Ruby versions and
implementations is planned for the future.

The `up`, `down`, `frame` and `show-stack` commands are provided. See
Pry's in-session help for more information on any of these commands.

**How to use:**

After installing `pry-stack_explorer`, just start Pry as normal (typically via a `binding.pry`), the stack_explorer plugin will be detected and used automatically.

* Install the [gem](https://rubygems.org/gems/pry-stack_explorer): `gem install pry-stack_explorer`
* Read the [documentation](http://rdoc.info/github/banister/pry-stack_explorer/master/file/README.md)
* See the [source code](http://github.com/pry/pry-stack_explorer)
* See the [wiki](https://github.com/pry/pry-stack_explorer/wiki) for in-depth usage information.

Example: Moving around between frames
--------

```
[8] pry(J)> show-stack

Showing all accessible frames in stack:
--
=> #0 [method]  c <Object#c()>
   #1 [block]   block in b <Object#b()>
   #2 [method]  b <Object#b()>
   #3 [method]  alphabet <Object#alphabet(y)>
   #4 [class]   <class:J>
   #5 [block]   block in <main>
   #6 [eval]    <main>
   #7 [top]     <main>
[9] pry(J)> frame 3

Frame number: 3/7
Frame type: method

From: /Users/john/ruby/projects/pry-stack_explorer/examples/example.rb @ line 10 in Object#alphabet:

     5:
     6: require 'pry-stack_explorer'
     7:
     8: def alphabet(y)
     9:   x = 20
 => 10:   b
    11: end
    12:
    13: def b
    14:   x = 30
    15:   proc {
[10] pry(J)> x
=> 20
```

Example: Modifying state in a caller
-------

```
Frame number: 0/3
Frame type: method

From: /Users/john/ruby/projects/pry-stack_explorer/examples/example2.rb @ line 15 in Object#beta:

    10:   beta
    11:   puts x
    12: end
    13:
    14: def beta
 => 15:   binding.pry
    16: end
    17:
    18: alpha
[1] pry(main)> show-stack

Showing all accessible frames in stack:
--
=> #0 [method]  beta <Object#beta()>
   #1 [method]  alpha <Object#alpha()>
   #2 [eval]    <main>
   #3 [top]     <main>
[2] pry(main)> up

Frame number: 1/3
Frame type: method

From: /Users/john/ruby/projects/pry-stack_explorer/examples/example2.rb @ line 10 in Object#alpha:

     5:
     6:
     7:
     8: def alpha
     9:   x = "hello"
 => 10:   beta
    11:   puts x
    12: end
    13:
    14: def beta
    15:   binding.pry
[3] pry(main)> x = "goodbye"
=> "goodbye"
[4] pry(main)> ^D

OUTPUT: goodbye
```

Output from above is `goodbye` as we changed the `x` local inside the `alpha` (caller) stack frame.

Limitations
-------------------------

* First release, so may have teething problems.
* Limited to Rubinius, and MRI 1.9.2+ at this stage.

Contact
-------

Problems or questions contact me at [github](http://github.com/banister)


License
-------

(The MIT License)

Copyright (c) 2011 John Mair (banisterfiend)

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

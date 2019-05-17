require 'busted.runner'()

local assert = require 'spec.assert'

describe("Euluna preprocessor should", function()

it("evaluate expressions", function()
  assert.c_gencode_equals([[
    local a = #['he' .. 'llo']
    local b = #[math.sin(-math.pi/2)]
    local c = #[true]
    local d = #[math.pi]
    local e = #[aster.Number{'dec','1'}]
  ]], [[
    local a = 'hello'
    local b = -1
    local c = true
    local d = 3.1415926535898
    local e = 1
  ]])
  assert.analyze_error("local a = #[function() end]", "unable to convert preprocess value of type")
end)

it("evaluate names", function()
  assert.c_gencode_equals([[
    $['print'] 'hello'
  ]], [[
    print 'hello'
  ]])
end)

it("parse if", function()
  assert.c_gencode_equals("[# if true then #] local a = 1 [# end #]", "local a = 1")
  assert.c_gencode_equals("[# if false then #] local a = 1 [# end #]", "")
  assert.c_gencode_equals([[
    local function f() [# if true then #] return 1 [# end #] end
  ]],[[
    local function f() return 1 end
  ]])
  assert.c_gencode_equals([[
    local function f()
      [# if true then #]
        return 1
      [# end #]
    end
  ]], [[
    local function f()
      return 1
    end
  ]])
  assert.analyze_error("[# if true then #]", "'end' expected")
end)

it("parse loops", function()
  assert.c_gencode_equals([[
    local a = 2
    ## for i=1,4 do
      a = a * 2
    ## end
  ]], [[
    local a = 2
    a = a * 2
    a = a * 2
    a = a * 2
    a = a * 2
  ]])
  assert.c_gencode_equals([[
    local a = 0
    ## for i=1,3 do
      do
        ## if i == 1 then
          a = a + 1
        ## elseif i == 2 then
          a = a + 2
        ## elseif i == 3 then
          a = a + 3
        ## end
      end
    ## end
  ]], [[
    local a = 0
    do a = a + 1 end
    do a = a + 2 end
    do a = a + 3 end
  ]])
  assert.c_gencode_equals([[
    local a = 0
    ## for i=1,3 do
      a = a + #[i]
    ## end
  ]], [[
    local a = 0
    a = a + 1
    a = a + 2
    a = a + 3
  ]])
end)

it("inject other symbol type", function()
  assert.c_gencode_equals([[
    local a: uint8 = 1
    local b: #[symbols['a'].attr.type]
  ]], [[
    local a: uint8 = 1
    local b: uint8
  ]])
end)

it("print symbol", function()
  assert.c_gencode_equals([=[
    local a: const integer = 1
    print #[tostring(symbols.a)]
  ]=], [[
    local const a = 1
    print 'symbol<const a: int64 = 1>'
  ]])
  assert.c_gencode_equals([=[
    for i:integer=1,2 do
      print(i, #[tostring(symbols.i)])
    end
  ]=], [[
    for i=1,2 do
      print(i, 'symbol<var i: int64>')
    end
  ]])
  assert.c_gencode_equals([[
    ## local aval = 1
    ## if true then
      local $['a']: const $['integer'] = #[aval]
      print #[tostring(scope:get_symbol('a'))]
    ## end
  ]], [[
    local const a = 1
    print 'symbol<const a: int64 = 1>'
  ]])
end)

it("print nodes", function()
end)

it("print symbol", function()
  assert.c_gencode_equals([=[
    ## local a = 1
    do
      do
        print #[a]
      end
    end
  ]=], [[
    do do print(1) end end
  ]])
  assert.c_gencode_equals([=[
    ## local MIN, MAX = 1, 2
    for i:integer=#[MIN],#[MAX] do
      print(i, #[tostring(symbols.i)])
    end
  ]=], [[
    for i:integer=1,2 do
      print(i, 'symbol<var i: int64>')
    end
  ]])
end)

it("report errors", function()
  assert.analyze_error("[# invalid() #]", "attempt to call")
end)

it("run brainfuck", function()
  assert.run('--generator c examples/brainfuck.euluna', 'Hello World!')
end)

end)
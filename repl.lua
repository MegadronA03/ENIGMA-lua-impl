local pprint = require("pprint")
local ophanim = require("ophanim")
local ldbg = require("lua_utils/debugger")

local OState = ophanim.newstate()
--pprint(OState)
OState.pprint = pprint

local quote_test = function ()
    io.write("testing quoting (55):\t")
    return OState:dispatch(OState.NegI.parse([[[a:1; b:{;a}; [a:55;b()][] ][] ]])).state
end
local contain_test = function ()
    io.write("testing isolation (1):\t")
    return OState:dispatch(OState.NegI.parse([[[a:1; b:{;a}; (a:55;b())[] ][] ]])).state
end
local grounding_test = function ()
    io.write("testing grounding (1):\t")
    return OState:dispatch(OState.NegI.parse([[[a:1; b:[;a]; [a:55;b()][] ][] ]])).state
end
local labeling_test = function ()
    io.write("testing labeling (3):\t")
    return OState:dispatch(OState.NegI.parse([[ [a : 2; a : 3; a][] ]])).state
end
local swap_test = function ()
    io.write("testing swap (3):\t") -- need to change how tests are performed
    return OState:dispatch(OState.NegI.parse([[ [
        a : 2;
        b : 3;
        a : b, b : a;
        a][] ]])).state
end
local passing_test = function ()
    io.write("testing passing (9):\t")
    return OState:dispatch(OState.NegI.parse([[ [
        NegI load;
        f : [
            b : 303;
            a : 9;
            pass [;r] [r:a,];
            a : 88;
        a];
        f[]
    ][] ]])).state
end

print("LOADING=========================================================")
pprint(contain_test())
pprint(quote_test())
pprint(grounding_test())
pprint(labeling_test())
pprint(swap_test())
pprint(passing_test())
print("NegI REPL v0.0.1 (Pre-Alpha)====================================")

local running = true
local rmf = OState.make.Manifest({ -- we describle REPL authority here, instead of using arbitrary commands
        can = {
            exit = {get = OState.make.Artifact([[return function (self) self.state.stop_repl() end]], "REPL can exit call")},
            reset = {get = OState.make.Artifact([[return function (self)
                while self.state.repl_layer < FLESH.KES:get_context() do FLESH.KES:pop_layer() end
                FLESH.KES:push_layer(FLESH.KES:get_context(),true)
            end]], "REPL can reset get")},
            help = {get = OState.make.Artifact([[]])}
        }
    },{
        repl_layer = OState.KES:get_context(),
        stop_repl = function () running = false end,
    })
local rsl = OState.KES:write_entry("REPL", rmf)


OState.KES:push_layer(OState.KES:get_context(),true)
while running do
    io.write(">")
    local input = io.read()
    local e = OState.NegI.parse(input) or OState.NegI.Manifests.gap
    e = OState:dispatch(e); e = e or OState.NegI.Manifests.gap -- evaluation
    e = OState:dispatch(e); e = (e ~= OState.NegI.Manifests.gap) and e or nil -- get
    OState.KES:stage_fill_reserve(e)
    OState.KES:commit()
    pprint((e or {}).state)
end
OState.KES:pop_layer()
-- starting to make the system alive
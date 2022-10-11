local command = require("discordia").class("command")


local commands = {}
local childCommands = {}
local commandAlias = {}


function command:__init(name, cb, parent)
    self._name = name
    self._cb = cb
    self._isChild = (parent ~= nil)
    self._description = ""
    self._category = ""

    if self._isChild then
        assert(commands[parent] ~= nil, "parent command does not exist")

        if childCommands[parent] == nil then
            childCommands[parent] = {}
        else
            assert(childCommands[parent][name] == nil, "child command already exists")
        end

        childCommands[parent][name] = self
    else
        assert(commands[name] == nil, "command already exists")

        commands[name] = self
    end

    return self
end

function command:Description(description)
    if description ~= nil then
        self._description = description

        return self
    else
        return self._description
    end
end

function command:Category(category)
    if category ~= nil then
        assert(category:match("[^%w%s]") == nil, "category must contain alphanumeric characters only")

        self._category = category

        return self
    else
        return self._category
    end
end

function command:CreateChild(name, cb)
    return command(name, cb, self._name)
end

function command:CreateAlias(alias)
    assert(self._isChild == false, "child commands cannot have aliases")

    commandAlias[alias] = self._name

    return self
end

function command:Name()
    return self._name
end

function command:GetChildren()
    return childCommands[self._name]
end

function command:GetChild(name)
    return (childCommands[self._name] ~= nil and childCommands[self._name][name])
end

function command:Evaluate(...)
    return self._cb(...)
end


function Exists(name)
    return (commands[name] and commandAlias[name])
end

function Get(name)
    return (commands[name] or commandAlias[name] ~= nil and commands[commandAlias[name]])
end

function GetAll()
    return commands
end

function GetChild(parent, child)
    return (childCommands[parent] ~= nil and childCommands[parent][child])
end


return {
    command = command,
    Exists = Exists,
    Get = Get,
    GetAll = GetAll,
    GetChild = GetChild
}
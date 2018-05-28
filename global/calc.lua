
local calc = {}

calc.precision = 0.000000000000000000000000001

function calc.greater(a, b)
    return a - b > calc.precision
end

function calc.less(a, b)
    return a - b < -calc.precision
end  

function calc.equal(a, b)
    return a - b < calc.precision and a - b > -calc.precision
end

function calc.unequal(a, b)
    return not calc.equal(a, b)
end

function calc.gequal(a, b)
    return a - b > -calc.precision
end

function calc.lequal(a, b)
    return a - b < calc.precision
end

function calc.tableShallowCopy(table)
    local newTable = {}
    for key, var in pairs(table) do
    	newTable[key] = var
    end
    
    return newTable
end

function calc.tableShallowAdditional(oldTable, addTable)
    for key, var in pairs(addTable) do
        --print("tableShallowAdditional", type(key), key)
        if type(var) == "table" then
            if not oldTable[key] then
                oldTable[key] = var
                --print("oldTable[key] = var")
            else
                calc.tableShallowAdditional(oldTable[key], var)
                 --print("tableShallowAdditionaloldTable[key] = var", key, var)
            end
        else
            --print(key, var)
            oldTable[key] = var
        end
    end
end

function calc.tableAttributeCopy(table, old)
    local newTable = old
    for key, var in pairs(table) do
    	var = 0
    end
    
    for key, var in pairs(table) do
        newTable[key] = var
    end

    return newTable
end

function calc.tableContain(table, value)
    for key, var in pairs(table) do
        if var == value then
        	return true
        end
    end
    return false
end

function calc.tableRandom(table)
    if table and #table > 0 then
        local rdIndex = MyRandom:random(1,#table)
        return table[rdIndex]
    end
    
    return nil
end

function calc.tableMultipleNumber(table, factor)
    for key, var in pairs(table) do
        if type(var) == "number" then
            table[key] = var * factor
        end
    end
end

function calc.exitBattle(cb)
    calc.cb = cb
    cc.Director:getInstance():getScheduler():setTimeScale(1)
    -- cc.Director:getInstance():getScheduler():setTimeScale(JSDSPEED)
    -- display.popScene()

    ReplaceSceneMgr.backMain()
    -- ResourceManager.removeResSpineExceptHero()
    -- releaseAllEffects()
    -- ReplaceSceneMgr.loadMainRes()
    -- display.replaceScene(MainScene.new())
    
    
end

function calc.serialize(o)  
    local str_serialize = {}
    if o == nil then  
        return "nil"
    end  
    if type(o) == "number" then  
        table.insert(str_serialize, tostring(o))
    elseif type(o) == "string" then  
        table.insert(str_serialize, string.format("%q", o))
    elseif type(o) == "table" then  
        table.insert(str_serialize, "{")
        for k,v in pairs(o) do  
            table.insert(str_serialize, " [")
            table.insert(str_serialize, calc.serialize(k))
            table.insert(str_serialize, "] = ")
            table.insert(str_serialize, calc.serialize(v))
            table.insert(str_serialize, ",")
        end   
        table.insert(str_serialize, "}")
    elseif type(o) == "boolean" then  
        table.insert(str_serialize, (o and "true" or "false"))
    elseif type(o) == "function" then  
        table.insert(str_serialize, "function" )
    else  
        error("cannot serialize a " .. type(o))  
    end  
    return table.concat(str_serialize)
end

return calc
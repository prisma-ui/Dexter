-- modules/SaveInstance.lua
local SaveInstance = {}
local env

function SaveInstance.InitDeps(deps)
    env = deps.env
end

function SaveInstance.Main()
    -- Fungsi untuk menyimpan model yang dipilih
    local function SaveModel(target)
        if typeof(env.saveinstance) == "function" then
            local success, err = pcall(function()
                env.saveinstance({
                    Object = target,
                    FileName = target.Name .. "_" .. os.time(),
                    mode = "rbxm",
                    Isolate = true
                })
            end)
            if success then
                print("[DEXTER] Model tersimpan: " .. target.Name)
            else
                warn("[DEXTER] Gagal menyimpan: " .. tostring(err))
            end
        else
            warn("[DEXTER] Eksekutor tidak mendukung saveinstance()")
        end
    end
    
    return {
        SaveModel = SaveModel
    }
end

return SaveInstance

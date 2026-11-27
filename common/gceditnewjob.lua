-- /gcedit's file menu: a new job file for any job, without a text editor. From your gear (/gcbuild: the example
-- with only what you own, as a draft to fill), the example as it is, or the example's sets emptied (its set names,
-- handlers and rules, no gear). The last two are written as <JOB>.lua in the character's folder, only when it has
-- none; LuAshitacast loads it on that job (on this job: now).
-- o: { imgui, palette, set_tip, feedback }
return function(o)
    local imgui, palette, set_tip, feedback = o.imgui, o.palette, o.set_tip, o.feedback
    local JOBS = { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG',
        'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' }
    local M = {}
    local pick = nil

    local function paths(job)
        local root = AshitaCore:GetInstallPath() .. 'config\\addons\\luashitacast\\'
        local dir = string.format('%s%s_%u\\', root, gState.PlayerName, gState.PlayerId)
        return root .. 'examples\\' .. job .. '.lua', dir .. job .. '.lua', dir
    end
    local function read(path)
        local f = io.open(path, 'rb')
        if f == nil then return nil end
        local t = f:read('*a')
        f:close()
        return t
    end
    local function current_job()
        return JOBS[AshitaCore:GetMemoryManager():GetPlayer():GetMainJob()]
    end
    local function write_new(job, text, what)
        local _, target = paths(job)
        if read(target) ~= nil then
            feedback(job .. '.lua already exists in your character folder: open it from the list above.')
            return
        end
        local f = io.open(target, 'wb')
        if f == nil then
            feedback('Could not write ' .. target .. '.')
            return
        end
        f:write(text)
        f:close()
        if current_job() == job then
            feedback(job .. '.lua written (' .. what .. '): loading it.')
            AshitaCore:GetChatManager():QueueCommand(1, '/lac load')
        else
            feedback(job .. '.lua written (' .. what .. '): it loads when you change to ' .. job .. '.')
        end
    end

    function M.Draw()
        imgui.Separator()
        imgui.TextUnformatted('New job file')
        imgui.SameLine()
        pick = pick or current_job() or 'WAR'
        if imgui.SmallButton(pick .. ' (change)##newjob_pick') then imgui.OpenPopup('##newjob_jobs') end
        if imgui.BeginPopup('##newjob_jobs') then
            for i, j in ipairs(JOBS) do
                if (i - 1) % 6 ~= 0 then imgui.SameLine() end
                if imgui.SmallButton(j .. '##newjob_' .. j) then
                    pick = j
                    imgui.CloseCurrentPopup()
                end
            end
            imgui.EndPopup()
        end
        local example, target = paths(pick)
        local exists = read(target) ~= nil
        if exists then
            imgui.SameLine()
            imgui.TextColored(palette.dim, '(you have ' .. pick .. '.lua)')
        end
        if imgui.SmallButton('From my gear##newjob_gear') then
            local ok, build = pcall(gFunc.LoadFile, 'common\\gcbuild.lua')
            if (not ok) or (type(build) ~= 'table') then
                feedback('common\\gcbuild.lua failed to load.')
            else
                local job, proposed, dir = build.Run({ pick }, gcinclude.Say, gcinclude.Err)
                if job ~= nil then
                    imgui.CloseCurrentPopup()
                    gcinclude.EditorDraft(job, proposed, dir)
                end
            end
        end
        if imgui.IsItemHovered() then
            set_tip('The ' .. pick .. ' example with only the gear you own, as ' .. pick .. '.proposed.lua: it opens here '
                .. 'to fill (on ' .. pick .. '), and its Save makes it your ' .. pick .. '.lua (/gcbuild).')
        end
        imgui.SameLine()
        local off = exists and (imgui.BeginDisabled ~= nil)
        if off then imgui.BeginDisabled() end
        if imgui.SmallButton('The example##newjob_example') and not exists then
            local text = read(example)
            if text == nil then feedback('No luashitacast\\examples\\' .. pick .. '.lua: copy GoomSwap\'s examples there.')
            else write_new(pick, text, 'the example as it is') end
        end
        if imgui.IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled or 0) then
            set_tip(exists and ('You have ' .. pick .. '.lua already.') or ('The ' .. pick .. ' example as it is, as your '
                .. pick .. '.lua: its sets name gear you may not own (Keep only my gear sorts that out).'))
        end
        imgui.SameLine()
        if imgui.SmallButton('Empty sets##newjob_empty') and not exists then
            local text = read(example)
            local setFile = gFunc.LoadFile('common\\gcsetfile.lua')
            local model = (text ~= nil) and setFile.Parse(text) or nil
            if model == nil then
                feedback('No luashitacast\\examples\\' .. pick .. '.lua to start from.')
            else
                -- every set kept by name, empty: the handlers, modes and rules stay as the example has them
                local lines = { '{' }
                for _, set in ipairs(model.list) do
                    if set.parentName == nil then
                        lines[#lines + 1] = '    ' .. setFile.FormatKey(set.name) .. ' = {},'
                    end
                end
                lines[#lines + 1] = '}'
                write_new(pick, string.sub(text, 1, model.open - 1) .. table.concat(lines, '\n')
                    .. string.sub(text, model.close + 1), 'the example\'s sets, empty')
            end
        end
        if imgui.IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled or 0) then
            set_tip(exists and ('You have ' .. pick .. '.lua already.') or ('The ' .. pick .. ' example\'s set names, '
                .. 'handlers and rules with no gear: fill each set here with Use worn or Gear.'))
        end
        if off then imgui.EndDisabled() end
    end
    return M
end

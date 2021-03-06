local issue = param.get("issue", "table")
local initiative = param.get("initiative", "table")

local view_module
local view_id

if initiative then
  issue = initiative.issue
  view_module = "initiative"
  view_id = initiative.id
else
  view_module = "issue"
  view_id = issue.id
end

ui.sidebar( "phases", function()










  local current_occured = false
  local failed = false
  
  for i, state in ipairs{ "admission", "discussion", "verification", "voting" } do
    local current = state == issue.state
    
    if current then
      current_occured = true
    end
    
    local phase_success = (
      (state == "admission" and issue.accepted)
        or (state == "discussion" and issue.half_frozen)
        or (state == "verification" and issue.fully_frozen and issue.state ~= "canceled_no_initiative_admitted")
        or (state == "voting" and issue.closed and issue.state ~= "canceled_no_initiative_admitted" and issue.state ~= "canceled_by_admin")
    )
    
    local state_names = {
      admission = _"Admission",
      discussion = _"Discussion",
      verification = _"Verification",
      voting = _"Voting"
    }








    local state_name = state_names[state] or state
    local function quorum_text(policy, quorum)
      local num
      local den
      
      if quorum == 1 then
        num = policy.issue_quorum_num
        den = policy.issue_quorum_den
      elseif quorum == 2 then
        num = policy.initiative_quorum_num
        den = policy.initiative_quorum_den
      end
      
      if num == nil or den == nil then
        return 0
      end
      
      if den == 100 or den == 10 then
        return _("#{percentage}%", { percentage = num * 100 / den })
      else
        return num .. "/" .. den
      end
      
    end

    if not failed then

      local klass = "phase"
      if current then klass = klass .. " current" end
      if not current and not current_occured and phase_success and not quorum and (quorum ~= 0) then
        klass = klass .. " finished"
      end

      ui.container{ attr = { class = klass }, content = function()
        local quorum
        if state == "admission" then        quorum = quorum_text(issue.policy, 1)
        elseif state == "verification" then quorum = quorum_text(issue.policy, 2)
        end

        if current then
          local time_left
          if issue.state_time_left:sub(1,1) ~= "-" then time_left = format.interval_text(issue.state_time_left, { mode = "time_left" })
          else                                          time_left = "phase ends soon"
          end
          ui.container{ attr = { class = "time event_time" },
            -- content = issue.end_time
            -- content = issue.state_time_left
            content = time_left
            -- KLAAS
          }
        elseif current_occured then
          local phase_duration = issue[state .. "_time"]
          ui.container{ attr = { class = "time" },
            content = _("#{duration}", { duration = format.interval_text(phase_duration) } )
          }
        else
          local text = "failed"
          if quorum then
            text = _("failed #{quorum}", { quorum = quorum })
          end
          if phase_success then
            if quorum == 0 then
              text = _"without quorum"
            elseif quorum then
              text = _("reached #{quorum}", { quorum = quorum })
            else
              text = _"finished"
            end
          elseif issue.state == "canceled_revoked_before_accepted" or
              issue.state == "canceled_after_revocation_during_discussion" or
              issue.state == "canceled_after_revocation_during_verification"
          then
            text = _"revoked"
          elseif issue.state == "canceled_by_admin" then
            text = _"canceled"
          end
          ui.container{ attr = { class = "status" },
            content = text
          }
        end

        ui.tag{ content = function()
          -- if current then
          --   ui.image{ attr = { class = "icon16" }, static = "icons/32/phase_current.png" }
          -- elseif not current_occured and not phase_success then
          --   ui.image{ attr = { class = "icon16" }, static = "icons/32/phase_failed.png" }
          -- elseif current_occured then
          --   ui.image{ attr = { class = "icon16" }, static = "icons/32/empty.png" }
          -- else
          --   ui.image{ attr = { class = "icon16" }, static = "icons/32/phase_finished.png" }
          -- end
          slot.put(" ")
          if current then
                  ui.container{ content = state_name, attr = { class = 'active text' } }
          else
                  ui.container{ content = state_name, attr = { class = 'text' } }
          end
        end }

        local help_texts = {
          admission = _("As soon as one initiative of this issue reaches the 1st quorum of #{quorum} support, the issue will proceed to discussion phase.", { quorum = quorum_text(issue.policy, 1) }),
          discussion = _"During the discussion phase, the issue is debated on while the initiators improve the proposals and reasons in their initiatives. Supporters of initiatives can write and rate suggestions for improvement.",
          verification = _("During the verification phase, existing initiatives cannot be changed anymore. Initiatives need to pass the 2nd quorum of #{quorum} at end of verification phase to become admitted for voting.", { quorum = quorum_text(issue.policy, 2) }),
          voting = _"During the voting phase, votes for all admitted initiatives in this issue can be cast. The final result will be calculated as soon as this phase ends."
        }
        ui.container { attr = { class = 'tooltip' }, content = function()
                ui.tag{ tag = 'span', content = function()
                        ui.tag{ tag = 'span', content= help_texts[state] }
                end}
        end}

      end }
    end
    
    if not phase_success and not current and not current_occured then
      failed = true
    end
  end
    
  if issue.closed then
    ui.sidebarSection( function()
      ui.heading { 
  attr = { class = 'h1' },
              level = 1, content = issue.state_name }
    end )
  end
      
  if issue.admin_notice then
    ui.sidebarSection( function()
      ui.heading { 
  attr = { class = 'h3' },
              level = 3, content = _"Administrative notice:" }
      slot.put(encode.html_newlines(issue.admin_notice)) 
    end )
  end
end )

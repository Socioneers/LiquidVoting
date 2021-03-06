local issue
local area

local issue_id = param.get("issue_id", atom.integer)
if issue_id then
        issue = Issue:new_selector():add_where{"id=?",issue_id}:single_object_mode():exec()
        issue:load_everything_for_member_id(app.session.member_id)
        area = issue.area

else
        local area_id = param.get("area_id", atom.integer)
        area = Area:new_selector():add_where{"id=?",area_id}:single_object_mode():exec()
        area:load_delegation_info_once_for_member_id(app.session.member_id)
end

local polling = param.get("polling", atom.boolean)

local policy_id = param.get("policy_id", atom.integer)
local policy

local preview = param.get("preview")

if #(slot.get_content("error")) > 0 then
        preview = false
end

if policy_id then
        policy = Policy:by_id(policy_id)
end

if issue_id then
        execute.view {
                module = "issue", view = "_head", 
                params = { issue = issue, member = app.session.member }
        }
        execute.view { 
                module = "issue", view = "_sidebar_state", 
                params = {
                        issue = issue
                }
        }
        execute.view { 
                module = "issue", view = "_sidebar_issue", 
                params = {
                        issue = issue
                }
        }
else
        execute.view {
                module = "area", view = "_head", 
                params = { area = area, member = app.session.member }
        }
        execute.view { 
                module = "initiative", view = "_sidebar_policies", 
                params = {
                        area = area,
                }
        }
end

ui.form{
        module = "initiative",
        action = "create",
        params = {
                area_id = area.id,
                issue_id = issue and issue.id or nil
        },
        attr = { class = "vertical" },
        content = function()

                if preview then
                        ui.section('section-initiative-preview', function()
                                ui.sectionHead( function()
                                        ui.heading{ level = 1, content = encode.html(param.get("name")) }
                                        if not issue then
                                                ui.container { content = policy.name }
                                                ui.heading{ level = 1, content = encode.html(param.get("issue_name")) }
                                        end
                                        if param.get("free_timing") then
                                                ui.container { content = param.get("free_timing") }
                                        end
                                end)
                                ui.sectionRow( function()

                                        -- slot.put("<br />")

                                        ui.field.hidden{ name = "formatting_engine", value = param.get("formatting_engine") }
                                        ui.field.hidden{ name = "policy_id", value = param.get("policy_id") }
                                        ui.field.hidden{ name = "name", value = param.get("name") }
                                        ui.field.hidden{ name = "issue_name", value = param.get("issue_name") }
                                        ui.field.hidden{ name = "issue_id", value = param.get("issue_id") }
                                        ui.field.hidden{ name = "draft", value = param.get("draft") }
                                        ui.field.hidden{ name = "free_timing", value = param.get("free_timing") }
                                        ui.field.hidden{ name = "polling", value = param.get("polling", atom.boolean) }
                                        local formatting_engine
                                        if config.enforce_formatting_engine then
                                                formatting_engine = config.enforce_formatting_engine
                                        else
                                                formatting_engine = param.get("formatting_engine")
                                        end
                                        ui.container{
                                                attr = { class = "draft" },
                                                content = function()
                                                        slot.put(format.wiki_text(param.get("draft"), formatting_engine))
                                                end
                                        }
                                        -- slot.put("<br />")

                                        ui.tag{
                                                tag = "input",
                                                attr = {
                                                        type = "submit",
                                                        class = "btn btn-default",
                                                        value = _'Publish now'
                                                },
                                                content = ""
                                        }
                                        -- slot.put("<br />")
                                        -- slot.put("<br />")
                                        ui.tag{
                                                tag = "input",
                                                attr = {
                                                        type = "submit",
                                                        name = "edit",
                                                        class = "btn btn-link",
                                                        value = _'Edit again'
                                                },
                                                content = ""
                                        }
                                        -- slot.put(" | ")
                                        if issue then
                                                ui.link{ content = _"Cancel", module = "issue", view = "show", id = issue.id }
                                        else
                                                ui.link{ content = _"Cancel", module = "area", view = "show", id = area.id }
                                        end
                                end )
                        end )
                else
                        execute.view{ module = "initiative", view = "_sidebar_wikisyntax" }

                        local _class = 'section-initiative'
                        local _content
                        if preview then
                                _content = _"Edit again"
                        elseif issue_id then
                                _class = 'section-initiative-new'
                                _content = _"Add a new competing initiative to issue"
                        else
                                _class = 'section-initiative-new'
                                _content = _"Create a new issue"
                        end

                        ui.section(_class, function()
                                ui.sectionHead( function()
                                        ui.heading { level = 1, content = _content }
                                end )
                                ui.sectionRow( function()
                                        if not preview and not issue_id then
                                                ui.container { attr = { class = "info" }, content = _"Before creating a new issue, please check any existant issues before, if the topic is already in discussion." }
                                                -- slot.put("<br />")
                                        end
                                        if not issue_id then
                                                local tmp = { { id = -1, name = "" } }
                                                for i, allowed_policy in ipairs(area.allowed_policies) do
                                                        if not allowed_policy.polling or app.session.member:has_polling_right_for_unit_id(area.unit_id) then
                                                                tmp[#tmp+1] = allowed_policy
                                                        end
                                                end
                                                -- slot.put("<br />")
                                                ui.heading { level = 2, content = _("What is the goal of your issue?") }
                                                -- ui.container { attr = { class = "chars" }, content = _"max. 140 chars" .. ", <span id='charcount-issue'>140</span> " .. _"left" }
                                                slot.put("<div class='chars'>" .. _"max. 140 chars" .. ", <span id='charcount-issue'>140</span> " .. _"left" .. "</div>")
                                                -- slot.put("(max. 140 chars, <span id='charcount-issue'>140</span> left)")
                                                ui.field.text{
                                                        attr = {
                                                                id = '_issue_title',
                                                                style = "width: 100%;",
                                                                maxlength = 140,
                                                                onkeyup = [[$('span#charcount-issue').html( 140-$('#_issue_title').val().length);]]
                                                        },
                                                        name  = "issue_name",
                                                        value = param.get("issue_name")
                                                }
                                                ui.heading{ level = 2, content = _"Please choose a policy for the new issue:" }
                                                ui.field.hidden{ name = "issue_id", value = param.get("issue_id") }
                                                ui.field.select{
                                                        name = "policy_id",
                                                        foreign_records = tmp,
                                                        foreign_id = "id",
                                                        foreign_name = "name",
                                                        value = param.get("policy_id", atom.integer) or area.default_policy and area.default_policy.id
                                                }
                                                if policy and policy.free_timeable then
                                                        local available_timings
                                                        if config.free_timing and config.free_timing.available_func then
                                                                available_timings = config.free_timing.available_func(policy)
                                                                if available_timings == false then
                                                                        error("error in free timing config")
                                                                end
                                                        end
                                                        ui.heading{ level = 4, content = _"Free timing:" }
                                                        if available_timings then
                                                                ui.field.select{
                                                                        name = "free_timing",
                                                                        foreign_records = available_timings,
                                                                        foreign_id = "id",
                                                                        foreign_name = "name",
                                                                        value = param.get("free_timing")
                                                                }
                                                        else
                                                                ui.field.text{
                                                                        name = "free_timing",
                                                                        value = param.get("free_timing")
                                                                }
                                                        end
                                                end
                                        end

                                        if issue and issue.policy.polling and app.session.member:has_polling_right_for_unit_id(area.unit_id) then
                                                -- slot.put("<br />")
                                                ui.field.boolean{ name = "polling", label = _"No admission needed", value = polling }
                                        end

                                        -- slot.put("<br />")
                                        ui.heading { level = 2, content = _"Enter a title for your initiative:" }
                                        -- slot.put("(max. 140 chars, <span id='charcount'>140</span> left)")
                                        slot.put("<div class='chars'>" .. _"max. 140 chars" .. ", <span id='charcount'>140</span> " .. _"left" .. "</div>")
                                        ui.field.text{
                                                attr = {
                                                        id = '_initiative_name',
                                                        style = "width: 100%;",
                                                        maxlength = 140,
                                                        onkeyup = [[$('span#charcount').html(
                                                        140-$('#_initiative_name').val().length
                                                        );]]
                                                },
                                                name  = "name",
                                                value = param.get("name")
                                        }
                                        ui.container { attr = { class = "info" }, content = _"The title is the figurehead of your iniative. It should be short but meaningful! As others identifies your initiative by this title, you cannot change it later!" }

                                        if not config.enforce_formatting_engine then
                                                -- slot.put("<br />")
                                                ui.heading { level = 4, content = _"Choose a formatting engine:" }
                                                ui.field.select{
                                                        name = "formatting_engine",
                                                        foreign_records = config.formatting_engines,
                                                        attr = {id = "formatting_engine"},
                                                        foreign_id = "id",
                                                        foreign_name = "name",
                                                        value = param.get("formatting_engine")
                                                }
                                        end
                                        -- slot.put("<br />")

                                        -- slot.put("<h2>Enter your proposal and/or reasons: (")
                                        ui.heading { level = 2, content = _("Enter your proposal and/or reasons:") }
                                        slot.put(
                                        ui.link{ attr = { class = "chars" }, content = _"Examples",
                                        static = 'examples.html',
                                        attr = { target = '_BLANK' }
                                }
                                )
                                -- slot.put(")</h2>")
                                ui.field.text{
                                        name = "draft",
                                        multiline = true, 
                                        attr = { style = "height: 50ex; width: 100%;" },
                                        value = param.get("draft")
                                }
                                if not issue or issue.state == "admission" or issue.state == "discussion" then
                                        ui.container { attr = { class = "info" }, content = _"You can change your text again anytime during admission and discussion phase" }
                                else
                                        ui.container { attr = { class = "info" }, content = _"You cannot change your text again later, because this issue is already in verfication phase!" }
                                end
                                -- slot.put("<br />")
                                ui.tag{
                                        tag = "input",
                                        attr = {
                                                type = "submit",
                                                name = "preview",
                                                class = "btn btn-default",
                                                value = _'Preview'
                                        },
                                        content = ""
                                }
                                -- slot.put("<br />")
                                -- slot.put("<br />")

                                if issue then
                                        ui.link{ content = _"Cancel", module = "issue", view = "show", id = issue.id }
                                else
                                        ui.link{ content = _"Cancel", module = "area", view = "show", id = area.id, class="lnk" }
                                end
                        end )
                end )
        end
end
}

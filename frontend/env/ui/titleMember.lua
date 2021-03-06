function ui.titleMember(title, title2)
  local member = app.session.member
  if type(title) == "table" then
    member = title
    title = title2
  end
  ui.title(function()
    ui.tag { tag = 'li', content = function()
    if member then
      ui.link { module = "member", view = "show", id = member.id, content = member.name }
    end
    end}
    if title then
    ui.tag { tag = 'li', content = title, attr = { class = 'last' }}
    end
  end)
end

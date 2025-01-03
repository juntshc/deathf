local addonName, addonTable = ...

-- Function to log death notes
function addonTable.LogDeathNote(message)
    if not HardcoreDeathNotesDB.DeathNotes then
        HardcoreDeathNotesDB.DeathNotes = {}
    end
    table.insert(HardcoreDeathNotesDB.DeathNotes, message)
    print("Death note logged.")  -- Debug print
end

-- Function to clear the death notes
function addonTable.ClearDeathNotes()
    HardcoreDeathNotesDB.DeathNotes = {}
    print("Death notes cleared.")
end

-- Function to retrieve all death notes
function addonTable.GetDeathNotes()
    return HardcoreDeathNotesDB.DeathNotes or {}
end
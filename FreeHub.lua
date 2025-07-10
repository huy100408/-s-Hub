-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Load Fluent UI once
local successFluent, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if not successFluent then
    warn("Failed to load Fluent UI:", Fluent)
    return
end

-- Create main window
local Window = Fluent:CreateWindow({
    Title = "Washedz Hub - Key System",
    SubTitle = "Enter your access key",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 360),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Create key tab
local KeyTab = Window:AddTab({ Title = "Key Validation", Icon = "lock" })

-- Add input box for key
local KeyInput = KeyTab:AddInput("KeyInput", {
    Title = "Enter your key",
    Placeholder = "Paste your key here",
    Default = "",
    Numeric = false,
    CharacterLimit = 64
})

-- All valid keys as set (copied from your list)
local validKeys = {
     ["AXV-7YF8-P2QJ-9E4C-H1GT"] = true,
    ["BZC-8ZG9-Q3RK-0F5D-I2HU"] = true,
    ["CYD-9AH0-R4SL-1G6E-J3IV"] = true,
    ["DZE-0BI1-S5TM-2H7F-K4JW"] = true,
    ["EAF-1CJ2-T6UN-3I8G-L5KX"] = true,
    ["FAG-2DK3-U7VO-4J9H-M6LY"] = true,
    ["GBH-3EL4-V8WP-5KAK-N7MZ"] = true,
    ["HCI-4FM5-W9XQ-6LBL-O8NA"] = true,
    ["IDJ-5GN6-X0YR-7MCM-P9OB"] = true,
    ["JEK-6HO7-Y1ZS-8NDN-QA0C"] = true,
    ["KFL-7IP8-Z2AT-9OEO-RB1D"] = true,
    ["LGM-8JQ9-A3BU-0PFP-SC2E"] = true,
    ["MHN-9KR0-B4CV-1QGQ-TD3F"] = true,
    ["NIO-0LS1-C5DW-2RHR-UE4G"] = true,
    ["OJP-1MT2-D6EX-3SIS-VF5H"] = true,
    ["PKQ-2NU3-E7FY-4TJT-WG6I"] = true,
    ["QLR-3OV4-F8GZ-5UKU-XH7J"] = true,
    ["RMS-4PW5-G9HA-6VLV-YI8K"] = true,
    ["SNT-5QX6-H0IB-7WMW-ZJ9L"] = true,
    ["TOU-6RY7-I1JC-8XNX-AK0M"] = true,
    ["UPV-7SZ8-J2KD-9YOY-BL1N"] = true,
    ["VQW-8TA9-K3LE-0ZPZ-CM2O"] = true,
    ["WRX-9UB0-L4MF-1AQA-DN3P"] = true,
    ["XSY-0VC1-M5NG-2BRB-EO4Q"] = true,
    ["YTZ-1WD2-N6OH-3CSC-FP5R"] = true,
    ["ZUA-2XE3-O7PI-4DTD-GQ6S"] = true,
    ["AVB-3YF4-P8QJ-5EUE-HR7T"] = true,
    ["BWC-4ZG5-Q9RK-6FVF-IS8U"] = true,
    ["CXD-5AH6-R0SL-7GWG-JT9V"] = true,
    ["DYE-6BI7-S1TM-2HXH-KU0W"] = true,
    ["EZF-7CJ8-T2UN-9IYI-LV1X"] = true,
    ["FAG-8DK9-U3VO-0JZJ-MW2Y"] = true,
    ["GBH-9EL0-V4WP-1KAK-NX3Z"] = true,
    ["HCI-0FM1-W5XQ-2LBL-OY40"] = true,
    ["IDJ-1GN2-X6YR-3MCM-PZ51"] = true,
    ["JEK-2HO3-Y7ZS-4NDN-QA62"] = true,
    ["KFL-3IP4-Z8AT-5OEO-RB73"] = true,
    ["LGM-4JQ5-A9BU-6PFP-SC84"] = true,
    ["MHN-5KR6-B0CV-7QGQ-TD95"] = true,
    ["NIO-6LS7-C1DW-8RHR-UE06"] = true,
    ["OJP-7MT8-D2EX-9SIS-VF17"] = true,
    ["PKQ-8NU9-E3FY-0TJT-WG28"] = true,
    ["QLR-9OV0-F4GZ-1UKU-XH39"] = true,
    ["RMS-0PW1-G5HA-2VLV-YI40"] = true,
    ["SNT-1QX2-H6IB-3WMW-ZJ51"] = true,
    ["TOU-2RY3-I7JC-4XNX-AK62"] = true,
}

-- Button to submit key
KeyTab:AddButton({
    Title = "Submit Key",
    Description = "Validate your access key",
    Callback = function()
        local enteredKey = (KeyInput.Value or ""):upper():gsub("%s+", "")
        if enteredKey == "" then
            Fluent:Notify({
                Title = "Key System",
                Content = "Please enter a key.",
                Duration = 3
            })
            return
        end

        if validKeys[enteredKey] then
            Fluent:Notify({
                Title = "Key System",
                Content = "Access granted! Loading hub...",
                Duration = 3
            })
            Window:Destroy()
            task.wait(1)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/washedz/WASHEDZ-HUB-DEV/refs/heads/main/WASHEDZ%20HUB", true))()
        else
            Fluent:Notify({
                Title = "Key System",
                Content = "Invalid key.",
                Duration = 3
            })
        end
    end
})

-- Optional: Get Key Button
KeyTab:AddButton({
    Title = "Get Key",
    Description = "Copy link to get a new key",
    Callback = function()
        local link = "https://loot-link.com/s?7RVf1Zyy"
        local success = false
        if setclipboard then
            setclipboard(link)
            success = true
        elseif syn and syn.write_clipboard then
            syn.write_clipboard(link)
            success = true
        end
        if success then
            Fluent:Notify({ Title = "Key System", Content = "Link copied! Paste in browser.", Duration = 4 })
        else
            Fluent:Notify({ Title = "Key System", Content = "Link: " .. link, Duration = 5 })
        end
    end
})

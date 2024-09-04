---
sidebar_position: 3
---
# 🌩️ Addy

Welcome to **Addy**, the `Addy` class is responsible for managing cloud configurations and interacting with **rbx-cloud** services. Follow this guide to learn how to utilize its powerful features for your Roblox projects!

---
## 📦 Installation
You can install the Addy package either via **Wally** or directly from the **Roblox Toolbox** ([Tutorial Here](./Download%20Package))

## 📖 Usage Example [![Go to API](https://img.shields.io/badge/Go%20to%20API-%F0%9F%94%8C-brightgreen)](/api)

### Creating an Instance of Addy

To get started, create a new instance of the `Addy` class using your cloud configuration:

```lua
local Addy = require(Packages.Addy)

local cloudConfig = {
    universeId = 123456789,
    authToken = "your-auth-token",
    CloudConfigEnum = Addy.CloudConfigEnums.SerialIndex,
    MaxRetries = 3,
    RetryDelay = 5,
}

local addyInstance = Addy.new(cloudConfig)
```

### Retrieving a Serial Number

You can retrieve a serial number for a unique ID using the `GetSerial` method:

```lua
local uniqueId = "item12345"
addyInstance:GetSerial(uniqueId):andThen(function(serialNumber)
    print("Serial number for " .. uniqueId .. ": " .. serialNumber)
end):catch(function(error)
    warn("Failed to retrieve serial: " .. error)
end)
```

### Retrieving Multiple Serial Numbers (Bulk)

You can retrieve serial numbers for multiple unique IDs using `GetBulkSerial`:

```lua
local uniqueIds = {"item12345", "item67890", "item111213"}
addyInstance:GetBulkSerial(uniqueIds):andThen(function(serialNumbers)
    for i, serial in ipairs(serialNumbers) do
        print("Serial for " .. uniqueIds[i] .. ": " .. serial)
    end
end):catch(function(error)
    warn("Failed to retrieve serials: " .. error)
end)
```

### Synchronous Retrieval (Optional)

If you prefer synchronous operations, you can use the `GetSerialAsync` and `GetBulkSerialAsync` methods:

```lua
local serial = addyInstance:GetSerialAsync("item12345")
print("Synchronous serial number: " .. (serial or "Failed"))

local bulkSerials = addyInstance:GetBulkSerialAsync({"item12345", "item67890"})
print("Synchronous bulk serials: ", bulkSerials)
```

### Cleanup

Once you're done with the `Addy` instance, make sure to properly clean it up:

```lua
addyInstance:Destroy()
```
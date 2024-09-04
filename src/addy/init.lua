--!strict

--[[
    Author: KinqAndi
    Date: 09/04/2024
    License: MIT
--]]

--[=[
    @class Addy
    🌤️ The `Addy` class is responsible for managing rbx-cloud configurations
    and interacting with rbx-cloud services.
]=]

-- Roblox Services
local HttpService = game:GetService("HttpService")

-- Package Imports
local Promise = require(script.Parent.Promise)

--[=[
    @type CloudConfigEnum number
    @within Addy
    Represents a valid enum type for the cloud configuration.
]=]

export type CloudConfigEnum = number

--[=[
    @type CloudConfig {universeId: number,authToken: string, CloudConfigEnum: CloudConfigEnum, MaxRetries: number?, RetryDelay: number?}
    @within Addy

    Contains the configuration for the cloud services.
]=]

export type CloudConfig = {
	universeId: number,
	authToken: string,
	CloudConfigEnum: CloudConfigEnum,
	MaxRetries: number?,
	RetryDelay: number?
}
--[=[
    @prop CloudConfigEnums {SerialNumber: 1}
    @within Addy
    Table containing cloud configuration enums used for validation.
]=]

local Addy = {
	CloudConfigEnums = {
		SerialNumber = 1
	}
}
Addy.__index = Addy

--[=[
    @param cloudConfig CloudConfig -- The configuration details for the cloud.
    @param baseUrl string? -- (Optional) The base URL of the cloud service. Defaults to `"https://www.rbx-cloud.com/"`.
    @return Addy -- A new instance of the `Addy` class.

    #### Usage Example

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
]=]
function Addy.new(cloudConfig: CloudConfig, baseUrl: string?)
	local self = setmetatable({}, Addy)
	
	local self = setmetatable({
		config = cloudConfig,
		baseUrl = baseUrl or "https://www.api.rbx-cloud.com/",
	}, Addy)

	self.getSerialUrl = self.baseUrl .. cloudConfig.universeId .. "/getSerial"
	self.getBulkSerials = self.baseUrl .. cloudConfig.universeId .. "/bulkGetSerial"

	self:_sendWarn("Initialized", false)
	
	return self
end

--[=[
    @param uniqueId string -- The unique identifier for which the serial is requested.
    @param dontIncrement boolean? -- (Optional) If true, the serial number is not incremented.
    @return Promise<number> -- A promise that resolves with the serial number.

    You can retrieve a serial number for a unique ID using the `GetSerial` method:

    #### Usage Example
    ```lua
    local uniqueId = "item12345"
    addyInstance:GetSerial(uniqueId):andThen(function(serialNumber)
        print("Serial number for " .. uniqueId .. ": " .. serialNumber)
    end):catch(function(error)
        warn("Failed to retrieve serial: " .. error)
    end)
    ```
]=]
function Addy:GetSerial(uniqueId: string, dontIncrement: boolean?): number?
	if self.config.CloudConfigEnum ~= self.CloudConfigEnums.SerialNumber then
		return self:_sendError("CloudConfigEnum is not set to SerialNumber. This method only supports SerialNumber cloud config enum.")
	end
	
	if typeof(uniqueId) ~= "string" then
		return self:_sendError("uniqueIds is expected to be a table.")
	end
	
	if string.len(uniqueId) >= 64 then
		return self:_sendError("Unique Id was longer than 64 characters! Max is 64 chars")
	end

	if typeof(dontIncrement) ~= "boolean" then
		return self:_sendError("dontIncrement i expected to be a boolean.")
	end

	local payLoad: {[string]: any} = HttpService:JSONEncode({
		["uniqueId"] = tostring(uniqueId),
		["dontIncrement"] = tostring(dontIncrement)
	})

	return Promise.retryWithDelay(function()
		return Promise.new(function(resolve, reject)
			local result = HttpService:JSONDecode(HttpService:PostAsync(self.getSerialUrl, payLoad, Enum.HttpContentType.ApplicationJson, false, {
				["x-api-key"] = self.config.authToken
			}))
			
			if result.error then
				return reject(result.error)
			end

			if result.serial then
				return resolve(result.serial)
			else
				return reject(result.error)
			end
		end)
	end, self.config.MaxRetries, self.config.RetryDelay):catch(function(err: string)
		return self:_sendWarn("Failed to get serial number for uniqueId: " .. uniqueId, true, err)
	end)
end

--[=[
    Retrieves serial numbers in bulk for multiple unique IDs from the cloud.
    @param dontIncrement boolean? -- (Optional) If true, the serial numbers are not incremented.
    @return Promise<{number}> -- A promise that resolves with a list of serial numbers.

    #### You can retrieve serial numbers for multiple unique IDs using `GetBulkSerial`:

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
]=]
function Addy:GetBulkSerial(uniqueIds: {string}, dontIncrement: boolean?): {[string]: number}?
	if self.config.CloudConfigEnum ~= self.CloudConfigEnums.SerialNumber then
		return self:_sendError("CloudConfigEnum is not set to SerialNumber. This method only supports SerialNumber cloud config enum.")
	end
	
	if typeof(uniqueIds) ~= "table" then
		return self:_sendError("uniqueIds is expected to be a table.")
	end
	
	if typeof(dontIncrement) ~= "boolean" then
		return self:_sendError("dontIncrement i expected to be a boolean.")
	end
	
	for _, id in uniqueIds do
		if string.len(id) >= 64 then
			return self:_sendError(`Unique Id ({id}) was longer than 64 characters! Max is 64 chars`)
		end
	end

	local payLoad: {[string]: any} = HttpService:JSONEncode({
		["uniqueIds"] = uniqueIds,
		["dontIncrement"] = tostring(dontIncrement)
	})

	return Promise.retryWithDelay(function()
		return Promise.new(function(resolve, reject)
			local result =  HttpService:JSONDecode(HttpService:PostAsync(self.getBulkSerials, payLoad, Enum.HttpContentType.ApplicationJson, false, {
				["x-api-key"] = self.config.authToken
			}))
			
			if result.error then
				return reject(result.error)
			end

			if result.results then
				local dictionary = {}
				
				for _, info in result.results do
					dictionary[info.uniqueId] = info.serial
				end
				
				return resolve(dictionary)
			else
				return reject(result.error)
			end
		end)
	end, self.config.MaxRetries, self.config.RetryDelay):catch(function(err: string)
		return self:_sendWarn("Failed to get serial numbers for uniqueIds", true, err)
	end)
end

--[=[
    @param uniqueId string -- The unique identifier for which the serial is requested.
    @param dontIncrement boolean? -- (Optional) If true, the serial number is not incremented.
    @return number? -- The serial number, or `nil` if the operation fails.
    
    #### If you prefer synchronous operations, you can use the `GetSerialAsync` and `GetBulkSerialAsync` methods:

    ```lua
    local serial = addyInstance:GetSerialAsync("item12345")
    print("Synchronous serial number: " .. (serial or "Failed"))

    local bulkSerials = addyInstance:GetBulkSerialAsync({"item12345", "item67890"})
    print("Synchronous bulk serials: ", bulkSerials)
    ```
]=]
function Addy:GetSerialAsync(uniqueId: string, dontIncrement: boolean?): number?
	return self:GetSerial(uniqueId, dontIncrement):expect()
end

--[=[
    Retrieves serial numbers in bulk for multiple unique IDs synchronously.

    @param uniqueIds {string} -- A list of unique IDs for which the serials are requested.
    @param dontIncrement boolean? -- (Optional) If true, the serial numbers are not incremented.
    @return number? -- The serial numbers, or `nil` if the operation fails.
]=]
function Addy:GetBulkSerialAsync(uniqueIds: {string}, dontIncrement: boolean?): number?
	return self:GetBulkSerial(uniqueIds, dontIncrement):expect()
end


--[=[
    Cleans up and destroys the Addy instance.
]=]
function Addy:Destroy()
	setmetatable(self, nil)
end

--errors
function Addy:_sendError(err: string)
	error("☁️Rbx-Cloud/addy: " .. err .. " | " .. debug.traceback())
end

--sends warning
function Addy:_sendWarn(err: string, traceback: boolean, ...)
	warn("☁️Rbx-Cloud/addy: " .. err, ..., debug.traceback())
end

return Addy
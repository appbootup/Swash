/*
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
*/

package main

import (
    "encoding/json"
    "fmt"
    "strconv"
    //	"strings"

    "github.com/hyperledger/fabric/core/chaincode/shim"
    pb "github.com/hyperledger/fabric/protos/peer"
)


// ============================================================================================================================
// write() - genric write variable into ledger
// 
// Shows Off PutState() - writting a key/value into the ledger
//
// Inputs - Array of strings
//    0   ,    1
//   key  ,  value
//  "abc" , "test"
// ============================================================================================================================
func write(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var key, value string
    var err error
    fmt.Println("starting write")

    if len(args) != 2 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 2. key of the variable and value to set"))
    }

    // input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    key = args[0]                                   //rename for funsies
    value = args[1]
    err = stub.PutState(key, []byte(value))         //write the variable into the ledger
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end write")
    return shim.Success(formatSuccess("NA","NA",nil))
}

func swappingStation_init(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error
    fmt.Println("starting swappingStation_init")

    if len(args) != 9 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 9"))
    }

    //input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    var swappingStation SwappingStation
    swappingStation.Id_swappingStation = args[0]
    swappingStation.Password = args[1]
    swappingStation.SwappingStationName = args[2]
    swappingStation.GeoCoordinates = args[3]
    swappingStation.Address = args[4]
    swappingStation.LicenseNumber = args[5]
    swappingStation.EmailId = args[6]
    swappingStation.ContactNumber = args[7]
    swappingStation.Company = args[8]
    swappingStation.DocType = "swappingStation"
    fmt.Println(swappingStation)

    //check if swappingStation already exists
    _, err = get_swappingStation(stub, swappingStation.Id_swappingStation)
    if err == nil {
        fmt.Println("This swappingStation already exists - " + swappingStation.Id_swappingStation)
        return shim.Error(formatError("NA","NA","This swappingStation already exists - " + swappingStation.Id_swappingStation))
    }

    //Store the swappingStation in ledger
    swappingStationAsBytes, _ := json.Marshal(swappingStation)
    err = stub.PutState(swappingStation.Id_swappingStation, swappingStationAsBytes)
    if err !=nil {
        fmt.Println("Could not store swappingStation")
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end init swappingStation ")
    return shim.Success(formatSuccess("NA","NA",nil))
}

func swappingStation_payToWallet(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error
    fmt.Println("starting swappingStation_payToWallet")

    if len(args) != 2 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 2"))
    }

    //input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    id_swappingStation :=  args[0]
    charge,_ := strconv.ParseInt(args[1],10,0)

    swappingStation,err := get_swappingStation(stub,id_swappingStation)
    if err != nil {
        fmt.Println("SwappingStation not found in Blockchain - " + id_swappingStation)
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    swappingStation.Id_swappingStation = id_swappingStation
    swappingStation.Wallet += charge

    //Store the swappingStation in ledger
    swappingStationAsBytes, _ := json.Marshal(swappingStation)
    err = stub.PutState(swappingStation.Id_swappingStation, swappingStationAsBytes)
    if err !=nil {
        fmt.Println("Could not store swappingStation")
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end payToWallet swappingStation ")
    return shim.Success(formatSuccess("NA","NA",nil))
}

func lender_init(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error
    fmt.Println("starting lender_init")

    if len(args) != 7 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 7"))
    }

    //input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    var lender Lender
    lender.Id_lender = args[0]
    lender.Password = args[1]
    lender.LenderName = args[2]
    lender.Address = args[3]
    lender.AadharNumber = args[4]
    lender.EmailId = args[5]
    lender.MobileNumber = args[6]
    lender.DocType = "lender"
    fmt.Println(lender)


    //check if user already exists
    _, err = get_lender(stub, lender.Id_lender)
    if err == nil {
        fmt.Println("This lender already exists - " + lender.Id_lender)
        return shim.Error(formatError("NA","NA","This lender already exists - " + lender.Id_lender))
    }

    //Store the lender in ledger
    lenderAsBytes, _ := json.Marshal(lender)
    err = stub.PutState(lender.Id_lender, lenderAsBytes)
    if err !=nil {
        fmt.Println("Could not store lender")
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end init lender ")
    return shim.Success(formatSuccess("NA","NA",nil))
}

func lender_payToWallet(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error
    fmt.Println("starting lender_payToWallet")

    if len(args) != 2 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 2"))
    }

    //input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    id_lender :=  args[0]
    charge,_ := strconv.ParseInt(args[1],10,0)

    lender,err := get_lender(stub,id_lender)
    if err != nil {
        fmt.Println("SwappingStation not found in Blockchain - " + id_lender)
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    lender.Id_lender = id_lender
    lender.Wallet += charge

    //Store the lender in ledger
    lenderAsBytes, _ := json.Marshal(lender)
    err = stub.PutState(lender.Id_lender, lenderAsBytes)
    if err !=nil {
        fmt.Println("Could not store lender")
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end payToWallet lender ")
    return shim.Success(formatSuccess("NA","NA",nil))
}

func lender_payFromWallet(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error
    fmt.Println("starting lender_payFromWallet")

    if len(args) != 2 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 2"))
    }

    //input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    id_lender :=  args[0]
    charge,_ := strconv.ParseInt(args[1],10,0)

    lender,err := get_lender(stub,id_lender)
    if err != nil {
        fmt.Println("SwappingStation not found in Blockchain - " + id_lender)
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    lender.Id_lender = id_lender
    lender.Wallet -= charge

    //Store the lender in ledger
    lenderAsBytes, _ := json.Marshal(lender)
    err = stub.PutState(lender.Id_lender, lenderAsBytes)
    if err !=nil {
        fmt.Println("Could not store lender")
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end payFromWallet lender ")
    return shim.Success(formatSuccess("NA","NA",nil))
}

func battery_init(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error
    fmt.Println("starting battery_init")

    if len(args) != 10 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 10"))
    }

    //input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    var battery Battery

    battery.Id_battery = args[0]
    battery.ModelNumber = args[1]
    SoC_uint64, _ := strconv.ParseUint(args[2],10,0)
    battery.SoC = uint8(SoC_uint64)
    SoH_uint64, _ := strconv.ParseUint(args[3], 10, 0)
    battery.SoH = uint8(SoH_uint64)
    EnergyContent_float64, _ := strconv.ParseFloat(args[4],0)
    battery.EnergyContent = float32(EnergyContent_float64)
    Cdc_uint64, _ := strconv.ParseUint(args[5],10,0)
    battery.Cdc = uint16(Cdc_uint64)
    battery.Owner = args[6]
    battery.User = args[7]
    battery.ManufacturerId = args[8]
    battery.ManufactureDate = args[9]
    battery.Status = "Available"
    battery.DocType = "battery"
    fmt.Println(battery)


    //Check if battery already exists
    _, err = get_battery(stub, battery.Id_battery)
    if err == nil {
        fmt.Println("This battery already exists - " + battery.Id_battery)
        return shim.Error(formatError("NA","NA","This battery already exists - " + battery.Id_battery))
    }

    //Store the battery in ledger
    batteryAsBytes, _ := json.Marshal(battery)
    err = stub.PutState(battery.Id_battery, batteryAsBytes)
    if err !=nil {
        fmt.Println("Could not store battery")
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end init battery ")
    return shim.Success(formatSuccess("NA","NA",nil))
}

func battery_transferBSS2Lnd(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error
    fmt.Println("starting battery_transferBSS2Lnd")

    if len(args) != 6 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 6"))
    }

    //input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    id_battery := args[0]

    battery ,err := get_battery(stub,id_battery)
    if err != nil {
        fmt.Println("battery not found in Blockchain - " + id_battery)
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    if battery.Status == "In_Use" {
        return shim.Error(formatError("NA","NA","Battery already in use - " + id_battery))
    }

    SoC_uint64, _ := strconv.ParseUint(args[1],10,0)
    battery.SoC = uint8(SoC_uint64)
    SoH_uint64, _ := strconv.ParseUint(args[2], 10, 0)
    battery.SoH = uint8(SoH_uint64)
    EnergyContent_float64, _ := strconv.ParseFloat(args[3],0)
    battery.EnergyContent = float32(EnergyContent_float64)
    Cdc_uint64, _ := strconv.ParseUint(args[4],10,0)
    battery.Cdc = uint16(Cdc_uint64)
    battery.User = args[5]
    battery.Status = "In_Use"

    //Store the battery in ledger
    batteryAsBytes, _ := json.Marshal(battery)
    err = stub.PutState(battery.Id_battery, batteryAsBytes)
    if err !=nil {
        fmt.Println("Could not store battery")
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end transferBSS2Lnd battery ")
    return shim.Success(formatSuccess("NA","NA",nil))
}

func battery_transferLnd2BSS(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error
    fmt.Println("starting battery_transferLnd2BSS")

    if len(args) != 6 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 6"))
    }

    //input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    id_battery := args[0]

    battery ,err := get_battery(stub,id_battery)
    if err != nil {
        fmt.Println("battery not found in Blockchain - " + id_battery)
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    if battery.Status == "In_Service" {
        return shim.Error(formatError("NA","NA","Battery already in service- " + id_battery))
    }

    SoC_uint64, _ := strconv.ParseUint(args[1],10,0)
    battery.SoC = uint8(SoC_uint64)
    SoH_uint64, _ := strconv.ParseUint(args[2], 10, 0)
    battery.SoH = uint8(SoH_uint64)
    EnergyContent_float64, _ := strconv.ParseFloat(args[3],0)
    battery.EnergyContent = float32(EnergyContent_float64)
    Cdc_uint64, _ := strconv.ParseUint(args[4],10,0)
    battery.Cdc = uint16(Cdc_uint64)
    battery.User = args[5]
    battery.Status = "In_Service"

    //Store the battery in ledger
    batteryAsBytes, _ := json.Marshal(battery)
    err = stub.PutState(battery.Id_battery, batteryAsBytes)
    if err !=nil {
        fmt.Println("Could not store battery")
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end transferLnd2BSS battery ")
    return shim.Success(formatSuccess("NA","NA",nil))
}

func battery_returnFromService(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error
    fmt.Println("starting battery_returnFromService")

    if len(args) != 6 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 6"))
    }

    //input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    id_battery := args[0]

    battery ,err := get_battery(stub,id_battery)
    if err != nil {
        fmt.Println("battery not found in Blockchain - " + id_battery)
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    if battery.Status == "Available" {
        return shim.Error(formatError("NA","NA","Battery already returned from service- " + id_battery))
    }

    SoC_uint64, _ := strconv.ParseUint(args[1],10,0)
    battery.SoC = uint8(SoC_uint64)
    SoH_uint64, _ := strconv.ParseUint(args[2], 10, 0)
    battery.SoH = uint8(SoH_uint64)
    EnergyContent_float64, _ := strconv.ParseFloat(args[3],0)
    battery.EnergyContent = float32(EnergyContent_float64)
    Cdc_uint64, _ := strconv.ParseUint(args[4],10,0)
    battery.Cdc = uint16(Cdc_uint64)
    battery.User = args[5]
    battery.Status = "Available"

    //Store the battery in ledger
    batteryAsBytes, _ := json.Marshal(battery)
    err = stub.PutState(battery.Id_battery, batteryAsBytes)
    if err !=nil {
        fmt.Println("Could not store battery")
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end returnFromService battery ")
    return shim.Success(formatSuccess("NA","NA",nil))
}

func battery_markStolen(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error
    fmt.Println("starting battery_markStolen")

    if len(args) != 1 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 1"))
    }

    //input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    id_battery := args[0]

    battery ,err := get_battery(stub,id_battery)
    if err != nil {
        fmt.Println("battery not found in Blockchain - " + id_battery)
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    if battery.Status == "Stolen" {
        return shim.Error(formatError("NA","NA","Battery already marked stolen - " + id_battery))
    }

    battery.Status = "Stolen"

    //Store the battery in ledger
    batteryAsBytes, _ := json.Marshal(battery)
    err = stub.PutState(battery.Id_battery, batteryAsBytes)
    if err !=nil {
        fmt.Println("Could not store battery")
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end markStolen battery ")
    return shim.Success(formatSuccess("NA","NA",nil))
}

func battery_markError(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error
    fmt.Println("starting battery_markError")

    if len(args) != 1 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 1"))
    }

    //input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    id_battery := args[0]

    battery ,err := get_battery(stub,id_battery)
    if err != nil {
        fmt.Println("battery not found in Blockchain - " + id_battery)
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    if battery.Status == "Error" {
        return shim.Error(formatError("NA","NA","Battery already marked error - " + id_battery))
    }

    battery.Status = "Error"

    //Store the battery in ledger
    batteryAsBytes, _ := json.Marshal(battery)
    err = stub.PutState(battery.Id_battery, batteryAsBytes)
    if err !=nil {
        fmt.Println("Could not store battery")
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end markError battery ")
    return shim.Success(formatSuccess("NA","NA",nil))
}

func battery_markExpired(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error
    fmt.Println("starting battery_markExpired")

    if len(args) != 1 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting 1"))
    }

    //input sanitation
    err = sanitize_arguments(args)
    if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    id_battery := args[0]

    battery ,err := get_battery(stub,id_battery)
    if err != nil {
        fmt.Println("battery not found in Blockchain - " + id_battery)
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    if battery.Status == "Expired" {
        return shim.Error(formatError("NA","NA","Battery already marked expired - " + id_battery))
    }

    battery.Status = "Expired"

    //Store the battery in ledger
    batteryAsBytes, _ := json.Marshal(battery)
    err = stub.PutState(battery.Id_battery, batteryAsBytes)
    if err !=nil {
        fmt.Println("Could not store battery")
        return shim.Error(formatError("NA","NA",err.Error()))
    }

    fmt.Println("- end markExpired battery ")
    return shim.Success(formatSuccess("NA","NA",nil))
}

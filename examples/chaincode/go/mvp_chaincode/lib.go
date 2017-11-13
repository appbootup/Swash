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
	"errors"
	"strconv"
	"github.com/hyperledger/fabric/core/chaincode/shim"
)

// =======================================
// Get SwappingStation - get a swappingStation asset from ledger
// =======================================
func get_swappingStation(stub shim.ChaincodeStubInterface, id_swappingStation string) (SwappingStation, error) {
	var swappingStation SwappingStation
	swappingStationAsBytes, err := stub.GetState(id_swappingStation)
	if err != nil {
		return swappingStation, errors.New("Failed to find swappingStation - " + id_swappingStation)
	}
	json.Unmarshal(swappingStationAsBytes, &swappingStation)

	if swappingStation.Id_swappingStation != id_swappingStation {
		return swappingStation, errors.New("SwappingStation does not exist - " + id_swappingStation)
	}

	return swappingStation, nil
}

func get_lender(stub shim.ChaincodeStubInterface, id_lender string) (Lender, error) {
	var lender Lender
	lenderAsBytes, err := stub.GetState(id_lender)
	if err != nil {
		return lender, errors.New("Failed to find lender - " + id_lender)
	}
	json.Unmarshal(lenderAsBytes, &lender)

	if lender.Id_lender != id_lender {
		return lender, errors.New("Lender does not exist - " + id_lender)
	}

	return lender, nil
}

func get_battery(stub shim.ChaincodeStubInterface, id_battery string) (Battery, error) {
	var battery Battery
	batteryAsBytes, err := stub.GetState(id_battery)
	if err != nil {
		return battery, errors.New("Failed to find battery - " + id_battery)
	}
	json.Unmarshal(batteryAsBytes, &battery)

	if battery.Id_battery != id_battery {
		return battery, errors.New("Battery does not exist - " + id_battery)
	}

	return battery, nil
}

func formatResponse(status string, code string, message string, result interface{}) interface{} {
	var response Response
	response.Status	= status
	response.Code	= code
	response.Message = message
	response.Result	= result
	responseAsBytes, _ := json.Marshal(response)
    resultAsString := "RESULT-->" + string (responseAsBytes) + "<--RESULT"
    
    if status == "OK" {
		//String is type casted to byte array
		return []byte (resultAsString)
	} else if status == "ERROR" {
		return resultAsString
	}
	//Code should not reach here. status can have only two values: OK and ERROR
	return nil
}


func formatSuccess(code string, message string, result interface{}) []byte {
	response := formatResponse("OK", code, message, result)
	return response.([]byte)
}
// Wrapper functions are provided as shim functions require type assertions for return values
func formatError(code string, message string, result interface{}) string{
	response := formatResponse("ERROR", code, message, result)
	return response.(string)
}
// ==============================================================
// Input Sanitation - dumb input checking, look for empty strings
// ==============================================================
func sanitize_arguments(strs []string) error{
	for i, val:= range strs {
		if len(val) <= 0 {
			return errors.New("Argument " + strconv.Itoa(i) + " must be a non-empty string")
		}
		if len(val) > 256 {
            errMsg := "Argument " + strconv.Itoa(i) + " must be <= 256 characters"
            return errors.New(errMsg)
		}
	}
	return nil
}

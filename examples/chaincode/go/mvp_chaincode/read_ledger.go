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
	
	"fmt"
	"encoding/json"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

// ============================================================================================================================
// Read - read a generic variable from ledger
//
// Shows Off GetState() - reading a key/value from the ledger
//
// Inputs - Array of strings
//  0
//  key
//  "abc"
// 
// Returns - string
// ============================================================================================================================
func swappingStation_read(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	var key, jsonResp string
	var err error
	fmt.Println("starting read")

	if len(args) != 1 {
		return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting key of the var to query"))
	}

	// input sanitation
	err = sanitize_arguments(args)
	if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
	}

	key = args[0]
	swappingStationAsbytes, err := stub.GetState(key)           //get the var from ledger
	if err != nil {
		jsonResp = "{\"Error\":\"Failed to get state for " + key + "\"}"
		return shim.Error(formatError("NA","NA",jsonResp))
	}

	var swappingStation SwappingStation
	json.Unmarshal(swappingStationAsbytes,&swappingStation)
	if swappingStation.DocType != "swappingStation" {
		jsonResp = "{\"Error\":\"No swappingStation was found with swappingStation id " + key + "\"}"
        return shim.Error(formatError("NA","NA",jsonResp))
	}

	fmt.Println("- end read")
	return shim.Success(formatSuccess("NA","NA",swappingStation))
}

func lender_read(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var key, jsonResp string
	var err error
	fmt.Println("starting read")

	if len(args) != 1 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting key of the var to query"))
	}

	// input sanitation
	err = sanitize_arguments(args)
	if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
	}

	key = args[0]
	lenderAsbytes, err := stub.GetState(key)           //get the var from ledger
	if err != nil {
		jsonResp = "{\"Error\":\"Failed to get state for " + key + "\"}"
        return shim.Error(formatError("NA","NA",jsonResp))
	}

	var lender Lender
	json.Unmarshal(lenderAsbytes,&lender)
	if lender.DocType != "lender" {
		jsonResp = "{\"Error\":\"No lender was found with lender id " + key + "\"}"
        return shim.Error(formatError("NA","NA",jsonResp))
		
	}


	fmt.Println("- end read")
	return shim.Success(formatSuccess("NA","NA",lender))
}

func battery_read(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var key, jsonResp string
	var err error
	fmt.Println("starting read")

	if len(args) != 1 {
        return shim.Error(formatError("NA","NA","Incorrect number of arguments. Expecting key of the var to query"))
	}

	// input sanitation
	err = sanitize_arguments(args)
	if err != nil {
        return shim.Error(formatError("NA","NA",err.Error()))
	}

	key = args[0]
	batteryAsbytes, err := stub.GetState(key)           //get the var from ledger
	if err != nil {
		jsonResp = "{\"Error\":\"Failed to get state for " + key + "\"}"
        return shim.Error(formatError("NA","NA",jsonResp))
	}

	var battery Battery
	json.Unmarshal(batteryAsbytes,&battery)
	if battery.DocType != "battery" {
		jsonResp = "{\"Error\":\"No battery was found with battery id " + key + "\"}"
        return shim.Error(formatError("NA","NA",jsonResp))
		
	}


	fmt.Println("- end read")
	return shim.Success(formatSuccess("NA","NA",battery))
}

func battery_readHistory(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	type AuditHistory struct {
		TxId    string   `json:"txId"`
		Value   Battery  `json:"value"`
	}
	var history []AuditHistory;
	var battery Battery

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	id_battery := args[0]
	fmt.Printf("- start getHistoryForBattery: %s\n", id_battery)

	// Get History
	resultsIterator, err := stub.GetHistoryForKey(id_battery)
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	for resultsIterator.HasNext() {
		historicValue, err := resultsIterator.Next()
		if err != nil {
			return shim.Error(err.Error())
		}
        txID := ""
		var tx AuditHistory
		tx.TxId = txID //copy transaction id over
		json.Unmarshal(historicValue.Value, &battery)     //un stringify it aka JSON.parse()
		if historicValue == nil {                   //battery has been deleted
			var emptyMarble Battery
			tx.Value = emptyMarble              //copy nil battery
		} else {
			json.Unmarshal(historicValue.Value, &battery) //un stringify it aka JSON.parse()
			tx.Value = battery                      //copy battery over
		}
		history = append(history, tx)              //add this tx to the list
	}
	fmt.Printf("- getHistoryForBattery returning:\n%s", history)

	//change to array of bytes
	historyAsBytes, _ := json.Marshal(history)     //convert to array of bytes
	return shim.Success(historyAsBytes)
}

//func getHistory(stub shim.ChaincodeStubInterface, args []string) pb.Response {
//	type AuditHistory struct {
//		TxId    string   `json:"txId"`
//		Value   Battery  `json:"value"`
//	}
//	var history []AuditHistory;
//	var battery Battery
//
//	if len(args) != 1 {
//		return shim.Error("Incorrect number of arguments. Expecting 1")
//	}
//
//	id_battery := args[0]
//	fmt.Printf("- start getHistoryForBattery: %s\n", id_battery)
//
//	// Get History
//	resultsIterator, err := stub.GetHistoryForKey(id_battery)
//	if err != nil {
//		return shim.Error(err.Error())
//	}
//	defer resultsIterator.Close()
//
//	for resultsIterator.HasNext() {
//		txID, historicValue, err := resultsIterator.Next()
//		if err != nil {
//			return shim.Error(err.Error())
//		}
//
//		var tx AuditHistory
//		tx.TxId = txID                              //copy transaction id over
//		json.Unmarshal(historicValue, &battery)     //un stringify it aka JSON.parse()
//		if historicValue == nil {                   //battery has been deleted
//			var emptyMarble Battery
//			tx.Value = emptyMarble              //copy nil battery
//		} else {
//			json.Unmarshal(historicValue, &battery) //un stringify it aka JSON.parse()
//			tx.Value = battery                      //copy battery over
//		}
//		history = append(history, tx)              //add this tx to the list
//	}
//	fmt.Printf("- getHistoryForBattery returning:\n%s", history)
//
//	//change to array of bytes
//	historyAsBytes, _ := json.Marshal(history)     //convert to array of bytes
//	return shim.Success(historyAsBytes)
//}


// ============================================================================================================================
// Get history of asset - performs a range query based on the start and end keys provided.
//
// Shows Off GetStateByRange() - reading a multiple key/values from the ledger
//
// Inputs - Array of strings
//       0     ,    1
//   startKey  ,  endKey
//  "product1" , "product5"
// ============================================================================================================================
//func getProductsByRange(stub shim.ChaincodeStubInterface, args []string) pb.Response {
//	if len(args) != 2 {
//		return shim.Error("Incorrect number of arguments. Expecting 2")
//	}
//
//	startKey := args[0]
//	endKey := args[1]
//
//	resultsIterator, err := stub.GetStateByRange(startKey, endKey)
//	if err != nil {
//		return shim.Error(err.Error())
//	}
//	defer resultsIterator.Close()
//
//	// buffer is a JSON array containing QueryResults
//	var buffer bytes.Buffer
//	buffer.WriteString("[")
//
//	bArrayMemberAlreadyWritten := false
//	for resultsIterator.HasNext() {
//		queryResultKey, queryResultValue, err := resultsIterator.Next()
//		if err != nil {
//			return shim.Error(err.Error())
//		}
//		// Add a comma before array members, suppress it for the first array member
//		if bArrayMemberAlreadyWritten == true {
//			buffer.WriteString(",")
//		}
//		buffer.WriteString("{\"Key\":")
//		buffer.WriteString("\"")
//		buffer.WriteString(queryResultKey)
//		buffer.WriteString("\"")
//
//		buffer.WriteString(", \"Record\":")
//		// Record is a JSON object, so we write as-is
//		buffer.WriteString(string(queryResultValue))
//		buffer.WriteString("}")
//		bArrayMemberAlreadyWritten = true
//	}
//	buffer.WriteString("]")
//
//	fmt.Printf("- getProductsByRange queryResult:\n%s\n", buffer.String())
//
//	return shim.Success(buffer.Bytes())
//}
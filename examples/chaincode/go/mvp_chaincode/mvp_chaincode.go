/*
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the

wit"License"); you may not use this file except in compliance the License.  You may obtain a copy of the License at

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
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

// SimpleChaincode example simple Chaincode implementation
type SimpleChaincode struct {
}

// ============================================================================================================================
// Asset Definitions - The ledger will battery, swappingStation and lender
// ============================================================================================================================

//
// Structure for response
//
type Response struct {

	Status		string	`json:"status"`
	Code		string	`json:"code"`
	Message		string	`json:"message"`
	Result		interface{} `json:"result"`
}

//
// Structure for `Battery`
//
type Battery struct {

	Id_battery	string	`json:"id_battery"`
	ModelNumber	string	`json:"modelNumber"`
	SoC	uint8	`json:"soC"`
	SoH	uint8	`json:"soH"`
	EnergyContent	float32	`json:"energyContent"`
	Cdc	uint16	`json:"cdc"`
	Owner	string	`json:"owner"`
	User	string	`json:"user"`
	Status	string	`json:"status"`
	ManufacturerId	string	`json:"manufacturerId"`
	ManufactureDate	string	`json:"manufactureDate"`
	DocType	string	`json:"docType"`
}

//
// Structure for `SwappingStation`
//
type SwappingStation struct {

	Id_swappingStation	string	`json:"id_swappingStation"`
	Password	string	`json:"password"`
	SwappingStationName	string	`json:"swappingStationName"`
	GeoCoordinates	string	`json:"geoCoordinates"`
	Address	string	`json:"address"`
	LicenseNumber	string	`json:"licenseNumber"`
	EmailId	string	`json:"emailId"`
	ContactNumber	string	`json:"contactNumber"`
	Company	string	`json:"company"`
	Wallet	int64	`json:"wallet"`
	DocType	string	`json:"docType"`
}

//
// Structure for `Lender`
//
type Lender struct {

	Id_lender	string	`json:"id_lender"`
	Password	string	`json:"password"`
	LenderName	string	`json:"lenderName"`
	Address	string	`json:"address"`
	AadharNumber	string	`json:"aadharNumber"`
	EmailId	string	`json:"emailId"`
	MobileNumber	string	`json:"mobileNumber"`
	Wallet	int64	`json:"wallet"`
	DocType	string	`json:"docType"`
}

// ============================================================================================================================
// Main
// ============================================================================================================================
func main() {
	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode - %s", err)
	}
}


// ============================================================================================================================
// Init - initialize the chaincode - mvp don’t need anything initlization, so let's run a dead simple test instead
// ============================================================================================================================
func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("MVP Is Starting Up")
	_, args := stub.GetFunctionAndParameters()
	var Aval int
	var err error

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	// convert numeric string to integer
	Aval, err = strconv.Atoi(args[0])
	if err != nil {
		return shim.Error("Expecting a numeric string argument to Init()")
	}

	// store compaitible marbles application version
	err = stub.PutState("marbles_ui", []byte("3.5.0"))
	if err != nil {
		return shim.Error(err.Error())
	}

	// this is a very simple dumb test.  let's write to the ledger and error on any errors
	err = stub.PutState("selftest", []byte(strconv.Itoa(Aval))) //making a test var "selftest", its handy to read this right away to test the network
	if err != nil {
		return shim.Error(err.Error())                          //self-test fail
	}

	fmt.Println(" - ready for action")                          //self-test pass
	return shim.Success(nil)
}


// ============================================================================================================================
// Invoke - Our entry point for Invocations
// ============================================================================================================================
func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	fmt.Println(" ")
	fmt.Println("starting invoke, for - " + function)

	// Handle different functions
	if function == "init" {                    	//initialize the chaincode state, used as reset
		return t.Init(stub)
	} else if function == "write" {            	//generic writes to ledger
		return write(stub, args)
	} else if function == "swappingStation_init"{
		return swappingStation_init(stub, args)
	} else if function == "swappingStation_read" {
		return swappingStation_read(stub, args)
	} else if function == "lender_init"{
		return lender_init(stub, args)
	} else if function == "lender_read" {
		return lender_read(stub, args)
	} else if function == "battery_init"{
		return battery_init(stub, args)
	} else if function == "battery_read" {
		return battery_read(stub, args)
	} else if function == "battery_readHistory" {
		return battery_readHistory(stub, args)
	} else if function == "swappingStation_payToWallet" {
		return swappingStation_payToWallet(stub, args)
	} else if function == "lender_payToWallet" {
		return lender_payToWallet(stub, args)
	} else if function == "lender_payFromWallet" {
		return lender_payFromWallet(stub, args)
	} else if function == "battery_transferBSS2Lnd" {
		return battery_transferBSS2Lnd(stub, args)
	} else if function == "battery_transferLnd2BSS" {
		return battery_transferLnd2BSS(stub, args)
	} else if function == "battery_returnFromService" {
		return battery_returnFromService(stub, args)
	} else if function == "battery_markStolen" {
		return battery_markStolen(stub, args)
	} else if function == "battery_markError" {
		return battery_markError(stub, args)
	} else if function == "battery_markExpired" {
		return battery_markExpired(stub, args)
	}
	// error out
	fmt.Println("Received unknown invoke function name - " + function)
	return shim.Error("Received unknown invoke function name - '" + function + "'")
}


// ============================================================================================================================
// Query - legacy function
// ============================================================================================================================
func (t *SimpleChaincode) Query(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Error("Unknown supported call - Query()")
}

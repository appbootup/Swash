#!/bin/bash

CHANNEL_NAME="$1"
FUNCTION_NAME="$2"
: ${CHANNEL_NAME:="mychannel"}
: ${TIMEOUT:="60"}
COUNTER=0
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

echo "Channel name : "$CHANNEL_NAME

verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
		echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
		echo
		exit 1
	fi
}

setGlobals () {

	if [ $1 -eq 0 -o $1 -eq 1 ] ; then
		CORE_PEER_LOCALMSPID="Org1MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
		if [ $1 -eq 0 ]; then
			CORE_PEER_ADDRESS=peer0.org1.example.com:7051
		else
			CORE_PEER_ADDRESS=peer1.org1.example.com:7051
		fi
	else
		CORE_PEER_LOCALMSPID="Org2MSP"
		CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
		if [ $1 -eq 2 ]; then
			CORE_PEER_ADDRESS=peer0.org2.example.com:7051
		else
			CORE_PEER_ADDRESS=peer1.org2.example.com:7051
		fi
	fi

	env |grep CORE
}

createChannel() {
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/orderer/localMspConfig
	CORE_PEER_LOCALMSPID="OrdererMSP"

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o orderer0:7050 -c $CHANNEL_NAME -f crypto/orderer/channel.tx >&log.txt
	else
		peer channel create -o orderer0:7050 -c $CHANNEL_NAME -f crypto/orderer/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}

## Sometimes Join takes time hence RETRY atleast for 5 times
joinWithRetry () {
	peer channel join -b $CHANNEL_NAME.block  >&log.txt
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "PEER$1 failed to join the channel, Retry after 2 seconds"
		sleep 2
		joinWithRetry $1
	else
		COUNTER=0
	fi
	verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel"
}

joinChannel () {
	for ch in 0 1 2 3; do
		setGlobals $ch
		joinWithRetry $ch
		echo "===================== PEER$ch joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep 2
		echo
	done
}


installChaincode () {
	PEER=$1
	setGlobals $PEER
	peer chaincode install -n mvp -v v1 -p github.com/hyperledger/fabric/examples/chaincode/go/mvp_chaincode >&log.txt
	res=$?
	cat log.txt
	verifyResult $res "Chaincode installation on remote peer PEER$PEER has Failed"
	echo "===================== Chaincode is installed on remote peer PEER$PEER ===================== "
	echo
}

instantiateChaincode () {
	PEER=$1
	setGlobals $PEER
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o orderer0:7050 -C $CHANNEL_NAME -n mvp -v v1 -p github.com/hyperledger/fabric/examples/chaincode/go/mvp_chaincode -c '{"Args":["init","100"]}' -P "OR	('Org0MSP.member','Org1MSP.member')" >&log.txt
	else
		peer chaincode instantiate -o orderer0:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -v v1 -p github.com/hyperledger/fabric/examples/chaincode/go/mvp_chaincode -c '{"Args":["init","100"]}' -P "OR	('Org0MSP.member','Org1MSP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on PEER$PEER on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

swappingStation_init (){
	PEER=$1
	Id_swappingStation=${2}
    Password=${3}
    SwappingStationName=${4}
    GeoCoordinates=${5}
    Address=${6}
    LicenseNumber=${7}
    EmailId=${8}
    ContactNumber=${9}
    Company=${10}


	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["swappingStation_init","'$Id_swappingStation'","'$Password'","'$SwappingStationName'","'$GeoCoordinates'","'$Address'","'$LicenseNumber'","'$EmailId'","'$ContactNumber'","'$Company'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["swappingStation_init","'$Id_swappingStation'","'$Password'","'$SwappingStationName'","'$GeoCoordinates'","'$Address'","'$LicenseNumber'","'$EmailId'","'$ContactNumber'","'$Company'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

swappingStation_payToWallet(){
	PEER=$1
    Id_swappingStation=${2}
    Charge=${3}

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["swappingStation_payToWallet","'$Id_swappingStation'","'$Charge'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["swappingStation_payToWallet","'$Id_swappingStation'","'$Charge'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

swappingStation_read() {
	PEER=$1
	Id_swappingStation=$2
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["swappingStation_read","'$Id_swappingStation'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLE  --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["swappingStation_read","'$Id_swappingStation'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "  
	echo 

}

lender_init (){
	PEER=$1
    Id_lender=${2}
    Password=${3}
    LenderName=${4}
    Address=${5}
    AadharNumber=${6}
    EmailId=${7}
    MobileNumber=${8}

	
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["lender_init","'$Id_lender'","'$Password'","'$LenderName'","'$Address'","'$AadharNumber'","'$EmailId'","'$MobileNumber'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["lender_init","'$Id_lender'","'$Password'","'$LenderName'","'$Address'","'$AadharNumber'","'$EmailId'","'$MobileNumber'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

lender_payToWallet(){
	PEER=$1
    Id_lender=${2}
    Charge=${3}

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["lender_payToWallet","'$Id_lender'","'$Charge'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["lender_payToWallet","'$Id_lender'","'$Charge'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

lender_payFromWallet(){
	PEER=$1
    Id_lender=${2}
    Charge=${3}

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["lender_payFromWallet","'$Id_lender'","'$Charge'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["lender_payFromWallet","'$Id_lender'","'$Charge'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

lender_read() {
	PEER=$1
	Id_lender=$2
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["lender_read","'$Id_lender'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLE  --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["lender_read","'$Id_lender'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "  
	echo 

}


battery_init (){

	PEER=$1
    Id_battery=${2}
    ModelNumber=${3}
    SoC=${4}
    SoH=${5}
    EnergyContent=${6}
    Cdc=${7}
    Owner=${8}
    User=${9}
    ManufacturerId=${10}
    ManufactureDate=${11}


	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_init","'$Id_battery'","'$ModelNumber'","'$SoC'","'$SoH'","'$EnergyContent'","'$Cdc'","'$Owner'","'$User'","'$ManufacturerId'","'$ManufactureDate'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_init","'$Id_battery'","'$ModelNumber'","'$SoC'","'$SoH'","'$EnergyContent'","'$Cdc'","'$Owner'","'$User'","'$ManufacturerId'","'$ManufactureDate'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

battery_transferBSS2Lnd (){

	PEER=$1

    Id_battery=${2}
    SoC=${3}
    SoH=${4}
    EnergyContent=${5}
    Cdc=${6}
    Id_lender=${7}


	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_transferBSS2Lnd","'$Id_battery'","'$SoC'","'$SoH'","'$EnergyContent'","'$Cdc'","'$Id_lender'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_transferBSS2Lnd","'$Id_battery'","'$SoC'","'$SoH'","'$EnergyContent'","'$Cdc'","'$Id_lender'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

battery_transferLnd2BSS (){

	PEER=$1

    Id_battery=${2}
    SoC=${3}
    SoH=${4}
    EnergyContent=${5}
    Cdc=${6}
    Id_swappingStation=${7}


	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_transferLnd2BSS","'$Id_battery'","'$SoC'","'$SoH'","'$EnergyContent'","'$Cdc'","'$Id_swappingStation'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_transferLnd2BSS","'$Id_battery'","'$SoC'","'$SoH'","'$EnergyContent'","'$Cdc'","'$Id_swappingStation'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

battery_returnFromService (){

	PEER=$1

    Id_battery=${2}
    SoC=${3}
    SoH=${4}
    EnergyContent=${5}
    Cdc=${6}
    Id_swappingStation=${7}


	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_returnFromService","'$Id_battery'","'$SoC'","'$SoH'","'$EnergyContent'","'$Cdc'","'$Id_swappingStation'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_returnFromService","'$Id_battery'","'$SoC'","'$SoH'","'$EnergyContent'","'$Cdc'","'$Id_swappingStation'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}


battery_markStolen() {
	PEER=$1
	Id_battery=$2
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_markStolen","'$Id_battery'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLE  --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_markStolen","'$Id_battery'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo

}

battery_markError() {
	PEER=$1
	Id_battery=$2
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_markError","'$Id_battery'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLE  --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_markError","'$Id_battery'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo

}

battery_markExpired() {
	PEER=$1
	Id_battery=$2
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_markExpired","'$Id_battery'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLE  --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_markExpired","'$Id_battery'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo

}

battery_read() {
	PEER=$1
	Id_battery=$2
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_read","'$Id_battery'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLE  --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_read","'$Id_battery'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo

}

battery_readHistory() {
	PEER=$1
	Id_battery=$2
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_readHistory","'$Id_battery'"]}' >&log.txt
	else
		peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLE  --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["battery_readHistory","'$Id_battery'"]}' >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo

}
######## BEGIN INITIALIZATION OF NETWORK #########
## Create channel
if [ $FUNCTION_NAME == "start" ];
then
	createChannel

	## Join all the peers to the channel
	joinChannel

	## Install chaincode on Peer0/Org0 and Peer2/Org1
	installChaincode 0
	installChaincode 2

	Instantiate chaincode on Peer0/Org0
	echo "Instantiating chaincode on Peer0/Org0 ..."
	instantiateChaincode 0
	sleep 2s

	######### INITIALIZATION OF NETWORK COMPLETED #########

	######### BEGIN USER FUNCTIONS ##########
elif [ $FUNCTION_NAME == "swappingStation_init" ];
then	
	swappingStation_init 0 ${3} ${4} ${5} ${6} ${7} ${8} ${9} ${10} ${11}
elif [ $FUNCTION_NAME == "swappingStation_payToWallet" ];
then
	swappingStation_payToWallet 0 ${3} ${4}
elif [ $FUNCTION_NAME == "swappingStation_read" ];
then	
	swappingStation_read 0 $3
elif [ $FUNCTION_NAME == "lender_init" ];
then	
	lender_init 0 ${3} ${4} ${5} ${6} ${7} ${8} ${9}
elif [ $FUNCTION_NAME == "lender_payToWallet" ];
then
	lender_payToWallet 0 ${3} ${4}
elif [ $FUNCTION_NAME == "lender_payFromWallet" ];
then
	lender_payFromWallet 0 ${3} ${4}
elif [ $FUNCTION_NAME == "lender_read" ];
then	
	lender_read 0 $3
elif [ $FUNCTION_NAME == "battery_init" ];
then	
	battery_init 0 ${3} ${4} ${5} ${6} ${7} ${8} ${9} ${10} ${11} ${12}
elif [ $FUNCTION_NAME == "battery_transferBSS2Lnd" ];
then
	battery_transferBSS2Lnd 0 ${3} ${4} ${5} ${6} ${7} ${8}
elif [ $FUNCTION_NAME == "battery_transferLnd2BSS" ];
then
	battery_transferLnd2BSS 0 ${3} ${4} ${5} ${6} ${7} ${8}
elif [ $FUNCTION_NAME == "battery_returnFromService" ];
then
	battery_returnFromService 0 ${3} ${4} ${5} ${6} ${7} ${8}
elif [ $FUNCTION_NAME == "battery_markStolen" ];
then
	battery_markStolen 0 $3
elif [ $FUNCTION_NAME == "battery_markError" ];
then
	battery_markError 0 $3
elif [ $FUNCTION_NAME == "battery_markExpired" ];
then
	battery_markExpired 0 $3
elif [ $FUNCTION_NAME == "battery_readHistory" ];
then
	battery_readHistory 0 $3
elif [ $FUNCTION_NAME == "battery_read" ];
then	
	battery_read 0 $3
else
	echo "No function called"
fi

echo
echo "===================== All GOOD, End-2-End execution completed ===================== "
echo
#exit 0

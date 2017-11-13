#!/bin/bash

CHANNEL_NAME="$1"
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
		setGlobals 0

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
	else
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}


updateAnchorPeers() {
        PEER=$1
        setGlobals $PEER

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
	else
		peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Anchor peer update failed"
	echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
	sleep 5
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
		COUNTER=1
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
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o orderer.example.com:7050 -C $CHANNEL_NAME -n mvp -v v1 -p github.com/hyperledger/fabric/examples/chaincode/go/mvp_chaincode -c '{"Args":["init","100"]}' -P "OR	('Org0MSP.member','Org1MSP.member')" >&log.txt
	else
		peer chaincode instantiate -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -v v1 -c '{"Args":["init","100"]}' -P "OR	('Org0MSP.member','Org1MSP.member')" >&log.txt
	fi
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on PEER$PEER on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

## Initialize owner 
initOwner() {
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","dhruv","BhandulaDhruv","Bosch","dhruv"]}'
#	sleep 2s
#	
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","xinyi","YangXinyi","Bosch","xinyi"]}'
#	sleep 2s
#	
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","yuvaraj","YuvarajRavi","Bosch","yuvaraj"]}'
#	sleep 2s
#	
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","pradeep","Pradeep","Bosch","pradeep"]}'
#	sleep 2s
#
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","kartik","KartikAtul","Bosch","kartik"]}'
#	sleep 2s
#
	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["iotDevice_init","1611300000308","247189FEA0C8","1234","rtp2_log"]}'
	sleep 2s

#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["user_init","dinesh","dinesh", "DineshKumaran", "Coimbatore", "dinesh@in.com", "Bosch"]}'
	sleep 2s

	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["user_init","rbac_log", "rbac_log", "RBAC_LOG", "Germany", "rbac_log@bosch.com", "Bosch"]}'
	sleep 2s

	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["user_init","rtp2_log", "rtp2_log", "RTP2_LOG", "Germany", "rtp2_log@bosch.com", "Bosch"]}'
	sleep 2s

	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["user_init","time_matters", "time_matters", "TIME_MATTERS", "Germany", "time_matters@lufthansa.com", "Lufthansa"]}'
	sleep 2s

	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["slOrder_init","slrbatim01","trReqN01","rtp2_log","rbac_log","time_matters","wintop_sh","trnNo01","01","{\"len_m\":\"10\",\"bre_m\":\"10\"}","Building^City_Name^State_name^Pin_code","Building^City_Name^State_name^Pin_code","2017-09-08 22:14:07","2017-09-08 22:14:07","AirCargo","{\"acc_mg\": \"1300\", \"temp_c\": \"20,21\", \"hum_per\": \"24,24\"}","-","rtp2_log"]}'
	sleep 2s	
	
	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["srOrder_init","srrtprba01", "srOrderReqNo01", "rtp2_log", "rbac_log", "wintop_sh", "trnNo01", "01", "{\"len_m\":\"10\",\"bre_m\":\"10\"}", "2017-09-08_22:14:07", "AirCargo", "{\"acc_mg\": \"1300\", \"temp_c\": \"20,21\", \"hum_per\": \"24,24\"}", "-", "rtp2_log"]}'
	sleep 2s

#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","kaales","Kaaleswaran","Bosch","kaales","kaales@in.gom"]}'
#	sleep 2s
#
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","christian","ChristianKoitzsch","Bosch","christian"]}'
#	sleep 2s
#	
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","rtp2_log","rtp2","Bosch","rtp2_log"]}'
#	sleep 2s
#
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","rbac_log","rbac","Bosch","rbac_log"]}'
#	sleep 2s
#
#        peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","time_matters","timeMatters","Lufthansa","time_matters"]}'
#        sleep 2s
#
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","guest","guestUser","Bosch","guest"]}'
#	sleep 2s

#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","mano","ManoRanjith","Bosch","mano","mano@in.gom"]}'
	
	cat log.txt
 
}
## Initialize product
initProduct() {
	peer chaincode invoke -o orderer0:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_product","prod1","Iphone64GB","kartik","Bosch"]}'
	cat log.txt
#
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","kaales","Kaaleswaran","Bosch","kaales","kaales@in.gom"]}'
#	sleep 2s
#
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","christian","ChristianKoitzsch","Bosch","christian"]}'
#	sleep 2s
#	
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","rtp2_log","rtp2","Bosch","rtp2_log"]}'
#	sleep 2s
#
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","rbac_log","rbac","Bosch","rbac_log"]}'
#	sleep 2s
#
#        peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","time_matters","timeMatters","Lufthansa","time_matters"]}'
#        sleep 2s
#
#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","guest","guestUser","Bosch","guest"]}'
#	sleep 2s

#	peer chaincode invoke -o orderer.example.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_owner","mano","ManoRanjith","Bosch","mano","mano@in.gom"]}'
	
	cat log.txt
 
}
## Initialize product
initProduct() {
	peer chaincode invoke -o orderer0:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_product","prod1","Iphone64GB","kartik","Bosch"]}'
	cat log.txt
 
}

## Initialize Contract
initContract() {
	peer chaincode invoke -o orderer0:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["init_contract","contract1","kartik","yuvaraj","B-5,Bluestones","Tower A, Indian Land","100","prod1","TDL1","Temerature","50","kartik","Bosch","Logistics"]}' 
	cat log.txt
 
}

## Get Contract info
contractInfo() {
	peer chaincode invoke -o orderer0:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["read","contract1"]}'
	cat log.txt
 
}


## Get Product info
productInfo() {
	peer chaincode invoke -o orderer0:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["read","prod1"]}'
	cat log.txt
 
}

## Get Product History
productHistory(){
	peer chaincode invoke -o orderer0:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["getHistory","prod1"]}'
	cat log.txt
}


## Change product ownership
changeOwner(){
	peer chaincode invoke -o orderer0:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mvp -c '{"Args":["set_owner","prod1","yuvaraj","Bosch"]}'

	cat log.txt
}




## Create channel
createChannel

## Join all the peers to the channel
joinChannel

## Install chaincode on Peer0/Org0 and Peer2/Org1
installChaincode 0
installChaincode 2

## Instantiate chaincode on Peer0/Org0
echo "Instantiating chaincode on Peer0/Org0 ..."
instantiateChaincode 0
sleep 5s

## Initialize user
# echo -e "\n\n\n Initialising user\n\n\n"
#initOwner
# sleep 2s

## Initialize product
#echo -e "\n\n\n Initialising product\n\n\n"
#initProduct
#sleep 5s

## Initialize contract
#echo -e "\n\n\n Initialising contract\n\n\n"
#initContract
#sleep 2s

## Get Contract info
#echo -e "\n\n\n Get Contract Info\n\n\n"
#contractInfo
#sleep 2s

## Get Product info
#echo -e "\n\n\n Get product Info\n\n\n"
#productInfo
#sleep 2s


## change Ownership of a product
#echo -e "\n\n\n Change owner\n\n\n"
#changeOwner
#sleep 2s

## Get Product History
#echo -e "\n\n\n Product history\n\n\n"
#productHistory
#sleep 2s

echo
echo "===================== All GOOD, End-2-End execution completed ===================== "
echo
#exit 0

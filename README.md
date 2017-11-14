# SWASH - Battery SWApping and SHaring System for E-Mobility

This repository contains the source code for blockchain based Battery SWApping and SHaring System named as SWASH by Robert Bosch Engineering and Business Solutions India Private Limited.
Chaincode is found here in the below link
https://github.com/mano-ranjith/Swash/tree/test/examples/chaincode/go/mvp_chaincode
To compile get the network running :
1. cd examples/e2e_cli && ./network_setup.sh
2. docker exec -t cli scripts/initializeNetwork.sh

## What's going on here?
> Background behind SWASH...

* In the past week or two, Delhi has turned into a chimney. Doctors are actively advising us to leave the city to live a longer healthy life. All our efforts to curb this menace have been short of the mark so far. E-mobility has long been touted as the solution to control vehicular pollution. However, there are many challenges with implementing it like high costs and low ranges. Battery is the key problem area. One possible solution can be Battery swapping and sharing or the SWASH model. However, keeping a track of the battery remains a huge problem which we are trying to solve using Blockchain technology.


> How it will help the soceity ?

* It will help reducing cost of e-vehicles therby encouraging more people to go with e-Mobility solutions.This will also help in reducing CO2 footprint both directly and indirectly.
* Battery manufacturing and disposal itself affects environment adversly and our solution will maximize battery life utilization.
* Since this system is based on Blockchain, it brings more trust and openess in the whole environment.
* People will pay for the Batteries based on their consumption. This enables a new path to improve usage of Electric vehicles among the people which inturn will reduce pollution and also helps to avoid the risk factors like fossil fuel depletion.


> How the SWASH System works?

* Battery Swapping Stations: (BSS)
	>It is a place where the user can go and swap the batteries once they get drained. It is similar to fuel stations and will be available at several places. In BSS, the charged batteries will be maintained and any registered user of this service can go and swap their batteries. Based on their consumption of energy from the battery, they will be charged. Here we introduce our own coin for this transactions called SWASH COINS.The user can pay cash and get these swash coins which in turn they will use this for their EV Battery swapping.
* Initially the user has to pay a deposit amount to get the battery for the first time. After everytime he swaps the battery, his deposit amount should be maintained at a particular level. The user can topup their wallets with their money  which will be added as SWASH COINS.
* At BSS each and every time before giving battery to the user,the battery details such as SoC, SoH, Energy Content etc., from the Battery Management System(BMS) will be read and updated in the Blockchain.
* while receiving the battery from the user also, BSS employee will connect the battery to the CAN and read out the battery details from the BMS. The system has an algorithm which will fix the cost for the battery usage based on the consumption and time period.
* This system also has Digital Identity verification using INDIACHAIN platform which is planned to be implemented. 



> System Architecture

![System Architecture]()

<img src="https://github.com/mano-ranjith/Swash/blob/test/image1.png"> 
<img src="https://github.com/mano-ranjith/Swash/blob/test/image2.png">

* The Battery and User details are stored in blockchain using Hyperledger Fabric Platform. It will have the SWASH COIN transaction and each battery's history.
* In Web UI, features like provision to add new battery into the system, view battery history, topup user wallet etc.,
* Python Based Solution to read battery parameters through CAN from the Battery Management System and communicate to the server.
* Temporary SQL Database for data storing which enhances more security and used as a filter before storing things in the Blockchain.
* This solution has a dedicated Web UI for the Battery Swapping stations and also a Android APP made for the users.
* In App, Users can see the batteries and their details which they are currently having, provison to search nearby swapping stations, and also they can see their wallet status.
* Theft Control is one of the main thing we concerned and implemented. In this solution, Aadhaar number of the user will be collected during sign up and they will be cross verified with the INDIACHAIN platform. And once the battery is marked as stolen, then the user can't charge/swap that battery in any station and we also have their aadhar number and we can catch them.

>Future Implementations Planned:

* User can add driver(s) from their mobile app. Most of the time, the drivers will go for swapping the battery. So the provision will be given to the user to add driver(s) whom will be mapped under their name. 
* Economy of Things: the batteries will be valued based on their worth by the system and each battery will have their own wallets.
* Provision for sharing the battery which people own. They can share their unused batteries through this Battery Swapping stations and get rewarded/earned. This will reduce the wastage of EV Batteries when they are not used and  kept idle.

>About Us

* We are engineers from Robert Bosch Engineering and Business Solutions India Pvt Ltd. Details about the individuals are given below.

	 * Dinesh Kumaran Nagarajan(RBEI/EAC7)(<dineshkumaran.nagarajan@in.bosch.com>)
	 * Manoranjith A Ponraj(RBEI/EAC7)(<ponraj.manoranjitha@in.bosch.com>)
	 * Dhruv Bhandula <bhandula.dhruv@in.bosch.com>

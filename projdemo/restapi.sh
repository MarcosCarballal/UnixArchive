#!/bin/bash

read myvar 

export HTTP_METHOD=$(echo $myvar | awk '{print $1}')
export REQUEST=$(echo $myvar | awk '{print $2}')
export VERSION=$(echo $myvar | awk '{print $3}')

#Constants
HTTP_200="HTTP/1.1 200 OK"
HTTP_201="HTTP/1.1 201 Created"
HTTP_404="HTTP/1.1 400 Bad Request"
HTTP_405="HTTP/1.1 405 Method Not Allowed"
HTTP_409="HTTP/1.1 409 Conflict"
JSON_CONT="Content-Type: application/json"

#echo -e "Debugging stuff \n Http method: $HTTP_METHOD \n Request type: $REQUEST \n Version type: $VERSION"
export REQUEST_NEED=$(echo $REQUEST | awk -F"/" '{print $2}') #This determines whether the program needs status or messages.
#echo -e "The program needs $REQUEST_NEED"
if [ "$HTTP_METHOD" == "GET" ];
then
	if [[ "$REQUEST_NEED" == "status" ]]
	then
		NUMLINES=$(cat messages.dat | wc -l)
		echo $HTTP_200
		echo $JSON_CONT
		echo "{\"record_count\": \"$NUMLINES\"}"
		exit 0
		
	elif	[[ "$REQUEST_NEED" == "messages" ]]
	then
#		echo -e "The http method was identified as GET"
		export USER_INPUT=$(echo $REQUEST | awk -F"/" '{print $3}')
		export numPat=^[0-9]+$
		export letPat=^[A-Za-z]+$
		#Determining UID of recipient
		if [[ $USER_INPUT =~ $numPat ]];
		then
#			echo -e "\tThe User input was indentified as numeric and is $USER_INPUT"
			# check /etc/passwd for numeric input
#			# echo -e "\t\t$(grep :"$USER_INPUT": /etc/passwd)"
			export ACTIVE_USER_LINE=$(grep x:"$USER_INPUT": /etc/passwd)
#			export ACTIVE_USER_LINE=$(cat /etc/passwd | cut -f1- -d ":")
		elif [[ $USER_INPUT =~ $letPat ]];
		then
#			echo -e "\tThe User input was indentified as non-numeric and is $USER_INPUT"
			export ACTIVE_USER_LINE=$(grep ^"$USER_INPUT": /etc/passwd)
		else
			echo $HTTP_404
			exit 1
		fi
		#echo -e "\t The active user line is $ACTIVE_USER_LINE"
                export USERID=$( echo $ACTIVE_USER_LINE | cut -s -f3 -d":")
		#echo "The UID is $UID"
	else
		echo $HTTP_405
		exit 1
	fi
	#Message retrieval and timesort
	OLDEST_MESSAGE=2000000000
	JSON_CONTENT=""
	while read line;
	do
		if [[ $( echo $line | cut -s -f1- -d",") =~ $USERID ]]
		then
			#timestamp testing
			if [[ $( echo $line | cut -s -f3 -d",") -lt $OLDEST_MESSAGE ]]
			then
				export OLDEST_MESSAGE=$(echo $line | cut -s -f3 -d",")
				JSON_CONTENT=$line 
			fi
		fi
	done <messages.dat
	if [[ "$JSON_CONTENT" == "" ]]
	then
		echo $HTTP_200
		echo $JSON_CONT
		echo "{}"
	else
		echo $HTTP_200
		echo $JSON_CONT
		#Figure out the username of the sender based on the User ID
		export SENDER_ID=$(echo $JSON_CONTENT | cut -s -f2 -d",")
		export SENDER_ID_LINE=$(grep x:"$SENDER_ID": /etc/passwd)
		export SENDER_NAME=$(echo "$SENDER_ID_LINE" | cut -s -f1 -d":")
		export MESSAGE=$(echo "$JSON_CONTENT" | cut -s -f4 -d"," )
		export TIMESTAMP=$(date --rfc-3339=seconds -d @$OLDEST_MESSAGE)
		echo "{"
		echo "\"sender\": \"$SENDER_NAME\""
		echo "\"message\": \"$MESSAGE\""
		echo "\"timestamp\": \"$TIMESTAMP\""

		echo "}"
	fi
fi

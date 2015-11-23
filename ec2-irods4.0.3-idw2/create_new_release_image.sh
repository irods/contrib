function terminate_instance() {
    aws ec2 terminate-instances --instance-ids $1
    if [ $? -eq 0 ]; then
        echo Instance $1 has been terminated.
    fi
}

if [ $# -lt 4 ]; then
   echo "usage:  $0 <irods folder> <irods version> <db plugin folder> <db plugin version>"
   echo "example: $0 4.1.3 4.1.3 4.1.3 1.5"
   exit
fi

# update user_data_script.sh 
IRODS_FOLDER=$1
IRODS_VERSION=$2
DB_PLUGIN_FOLDER=$3
DB_PLUGIN_VERSION=$4
sed -i "s|^\./deploy\.sh.*|\./deploy\.sh $IRODS_FOLDER $IRODS_VERSION $DB_PLUGIN_FOLDER $DB_PLUGIN_VERSION|g" user_data_script.sh

# run instance from Ubuntu base image 
INSTANCE_ID=$(aws ec2 run-instances --image-id ami-bb14dad0 --security-groups "iRODS" --instance-type t2.micro --user-data file://user_data_script.sh | jq '.Instances[0].InstanceId' |  sed 's/\"//g' )

if [ $? -eq 0 ]; then
    echo Created instance $INSTANCE_ID.
else
    echo Error encountered when createing instance $INSTANCE_ID
fi

echo Waiting for instance to be in a running state.
sleep 20

# wait for the instance to be in a running state 
CURRENT_STATUS=initialization
CNTR=0
while [ $CURRENT_STATUS != "passed" -a $CNTR -lt 60 ]; do
    CURRENT_STATUS=$(aws ec2 describe-instance-status --instance-ids $INSTANCE_ID | jq '.InstanceStatuses[0].InstanceStatus.Details[0].Status' | sed 's/\"//g')
    let CNTR=CNTR+1
    echo $CURRENT_STATUS
    sleep 10
done
echo Instance $INSTANCE_ID is now running.

if [ $CNTR -eq 60 ]; then
   echo Timeout while waiting for $INSTANCE_ID to enter running state.
   terminate_instance $INSTANCE_ID
   exit
fi

# create image from this instance
echo IRODS_VERSION=$IRODS_VERSION
aws ec2 create-image --instance-id $INSTANCE_ID --name irods_${IRODS_VERSION}_with_ubuntu_14.04 --description "irods $IRODS_VERSION with Cloud Browser on Ubuntu 14.04"
if [ $? -eq 0 ]; then
    echo Created image irods_${IRODS_VERSION}_with_ubuntu_14.04. 
else
    echo Error creating image.
    terminate_instance $INSTANCE_ID
    exit
fi

# terminate instance
sleep 60
terminate_instance $INSTANCE_ID

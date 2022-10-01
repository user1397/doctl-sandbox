#!/bin/bash

# Declare variables
PROJECT_NAME=doctl-test-project
PROJECT_PURPOSE=sandbox
PROJECT_ENV=Development
DROPLET_NAME=doctl-test-droplet
DROPLET_REGION=nyc1
DROPLET_SIZE=s-1vcpu-512mb-10gb
DROPLET_IMAGE=ubuntu-22-04-x64
USER_DATA=cloud-init.sh
SSH_KEY_NAME=doctl-test-sshkey
SSH_KEY_PATH=~/.ssh/id_rsa.pub
SSH_KEY_FINGERPRINT=$(ssh-keygen -l -E md5 -f $SSH_KEY_PATH | awk '{print $2}' | sed 's|MD5:||')
SSH_PORT=55022
FIREWALL_NAME=doctl-test-firewall
MY_IP=$(curl -s http://ipinfo.io/ip)

# Create resources
if [ "${1}" == "create" ]; then
   echo "#####################"
   echo "Creating SSH Key"
   echo "#####################"
   doctl compute ssh-key import $SSH_KEY_NAME \
     --public-key-file $SSH_KEY_PATH
   echo "#####################"
   echo "...Done"

   echo "#####################"
   echo "Creating droplet"
   echo "#####################"
   GET_DROPLET=$(doctl compute droplet get $DROPLET_NAME --format Name --no-header)
   if [ "${GET_DROPLET}" == "$DROPLET_NAME" ]; then
     echo "The droplet with name $DROPLET_NAME already exists."
     exit 1
    else
     doctl compute droplet create \
       $DROPLET_NAME \
       --region $DROPLET_REGION \
       --size $DROPLET_SIZE \
       --image $DROPLET_IMAGE \
       --user-data-file $USER_DATA \
       --ssh-keys $SSH_KEY_FINGERPRINT     
   fi
   echo "#####################"
   sleep 10
   echo "...Done"

   echo "#####################"
   echo "Creating project"
   echo "#####################"
   doctl projects create \
     --name $PROJECT_NAME \
     --purpose $PROJECT_PURPOSE \
     --environment $PROJECT_ENV
   echo "#####################"
   echo "...Done"
   
   DROPLET_ID=$(doctl compute droplet get $DROPLET_NAME --template {{.ID}})
   PROJECT_ID=$(doctl projects list --format ID,Name | grep $PROJECT_NAME | awk '{print $1}')
   
   echo "#####################"
   echo "Assigning droplet to project"
   echo "#####################"
   doctl projects resources assign $PROJECT_ID \
     --resource=do:droplet:$DROPLET_ID
   echo "#####################"
   sleep 15
   echo "...Done"
   
   echo "#####################"
   echo "Creating reserved IP and assigning to droplet"
   echo "#####################"
   doctl compute reserved-ip create --droplet-id $DROPLET_ID
   echo "#####################"
   echo "...Done"
   
   echo "#####################"
   echo "Creating firewall and assigning it to droplet"
   echo "#####################"
   doctl compute firewall create \
     --name $FIREWALL_NAME \
     --droplet-ids $DROPLET_ID \
     --inbound-rules protocol:tcp,ports:$SSH_PORT,address:$MY_IP \
     --outbound-rules "protocol:tcp,ports:1-65535,address:0.0.0.0/0 protocol:udp,ports:1-65535,address:0.0.0.0/0"
   echo "#####################"
   echo "...Done"
 
 # Destroy resources
 elif [ "${1}" == "destroy" ]; then
   echo "#####################"
   echo "Destroying firewall"
   doctl compute firewall delete -f \
     $(doctl compute firewall list --format ID,Name | grep $FIREWALL_NAME | awk '{print $1}') 
   echo "#####################"
   echo "...Done"

   echo "#####################"
   echo "Destroying reserved IP"
   doctl compute reserved-ip delete -f \
     $(doctl compute reserved-ip list | grep $DROPLET_NAME | awk '{print $1}')
   echo "#####################"
   echo "...Done"

   echo "#####################"
   echo "Destroying droplet"
   doctl compute droplet delete -f $DROPLET_NAME
   echo "#####################"
   sleep 10
   echo "...Done"

   echo "#####################"
   echo "Destroying project"
   PROJECT_ID=$(doctl projects list --format ID,Name | grep $PROJECT_NAME | awk '{print $1}')
   doctl projects delete -f $PROJECT_ID
   echo "#####################"
   echo "...Done"

   echo "#####################"
   echo "Destroying SSH KEY"
   doctl compute ssh-key delete -f $SSH_KEY_FINGERPRINT
   echo "#####################"
   echo "...Done"
 
 else 
   echo "Incorrect option specified; please choose either 'create' or 'destroy'."
fi
#!/bin/bash
#title           :setup_mongodb_ubuntu_16_04.sh
#description     :Script will install MongoDB Ubuntu 16.04.
#author		     :Drilon Berisha
#version         :0.1
#usage		     :./setup_mongodb_ubuntu_16_04.sh install|remove
#==============================================================================

function install_mongo {

# Import the Public Key used by the Ubuntu Package Manager
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6

# Create a file list for mongoDB to fetch the current repository
sudo echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list

# Update the Ubuntu Packages
sudo apt update 

# Install MongoDB
sudo apt install mongodb-org -y

echo "Configure Mongo to startup"
sudo systemctl enable mongod

echo "Enable Mongo Authentication for security"

sudo sed -i 's/#security:/security:/g' /etc/mongod.conf
sudo sed -i '/security:/ a \  authorization: enabled' /etc/mongod.conf

echo "Restarting Mongo DB"
sudo systemctl restart mongod

# Wait for MongoDB to boot
RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MongoDB service startup..."
    sleep 5
    mongo admin --eval "help" >/dev/null 2>&1
    RET=$?
done

echo "Create Admin and app users"
# Admin User
MONGODB_ADMIN_USER="admin"
MONGODB_ADMIN_PASS="AdminPassword0198"

# Application Database User
AA_APP_DATABASE="dbapp1"
AA_APP_USER="dbapp1"
AA_APP_PASS="Password01"

# Create the admin user
echo "=> Creating admin user with a password in MongoDB"
mongo admin --eval "db.createUser({user: '$MONGODB_ADMIN_USER', pwd: '$MONGODB_ADMIN_PASS', roles:[{role:'root',db:'admin'}]});"

sleep 3

#Creating first DB
echo "=> Creating an ${AA_APP_DATABASE} user with a password in MongoDB"
mongo admin -u $MONGODB_ADMIN_USER -p $MONGODB_ADMIN_PASS << EOF
use $AA_APP_DATABASE
db.createUser({user: '$AA_APP_USER', pwd: '$AA_APP_PASS', roles:[{role:'dbOwner', db:'$AA_APP_DATABASE'}]})
EOF

sleep 1

# If everything went well
echo "=> MondoDB Done!"

echo "========================================================================"
echo "You can now connect to the admin MongoDB server using:"
echo ""
echo "    mongo admin -u $MONGODB_ADMIN_USER -p $MONGODB_ADMIN_PASS --host localhost --port 27017"
echo "    mongo -u "$AA_APP_USER" -p "$AA_APP_PASS" --authenticationDatabase "$AA_APP_DATABASE" --host localhost --port 27017"
echo ""
echo "Please remember to save the admin password as soon as possible!"
echo "========================================================================"

}

function remove_mongo {
  echo "Stoping Services"
  sudo systemctl stop mongod
  echo "Removing Services"
  sudo apt-get purge mongodb-org* -y
  echo "Removing Log Folder"
  sudo rm -r /var/log/mongodb
  echo "Removing Lib Folder"
  sudo rm -r /var/lib/mongodb
  echo "Removing Config File"
  sudo rm -r /etc/mongod.conf*
  echo "Removing TMP"
  sudo rm -r /tmp/mongo*
}

# Show Menu
if [ ! -n "$1" ]; then
    echo ""
    echo -e  "\033[35;1mA standard setup would be: install, remove\033[0m"
    echo ""
    echo -e  "\033[35;1mSelect from the options below to use this script:- \033[0m"

    echo -n  "$0"
    echo -ne "\033[36m install\033[0m"
    echo     " - This will install mongodb."

    echo -n "$0"
    echo -ne "\033[36m stop\033[0m"
    echo     " - This will remove mongodb."
    
    echo ""
    exit
fi
# End Show Menu


case $1 in
install)
    install_mongo
    ;;
remove)
    remove_mongo
    ;;
esac

exit

#!/bin/sh
#title           :setup_mongodb_rhel.sh
#description     :Script will install MongoDB.
#author		       :Drilon Berisha
#version         :0.1
#usage		      :./setup_mongodb_rhel.sh install|remove
#==============================================================================

function install_mongo {

echo "Add following content in yum repository configuration"

echo '
[MongoDB]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
' > /etc/yum.repos.d/mongodb.repo

yum repolist

echo "Install Mongo"
sudo yum install mongodb-org -y

echo "Configure Mongo to startup"
sudo systemctl enable mongod

echo "Enable Mongo Authentication for security"

sed -i 's/#security:/security:/g' /etc/mongod.conf
sed -i '/security:/ a \  authorization: enabled' /etc/mongod.conf

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
  sudo yum erase $(rpm -qa | grep mongodb-org) -y
  sudo rm -r /var/log/mongodb
  sudo rm -r /var/lib/mongo
  sudo rm -r /etc/mongod.conf*
  sudo rm -r /tmp/mongo*
}

# Show Menu
if [ ! -n "$1" ]; then
    echo ""
    echo -e  "\033[35;1mNOTICE: Edit env.conf before using\033[0m"
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

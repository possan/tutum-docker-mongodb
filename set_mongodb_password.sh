#!/bin/bash

if [ -f /.mongodb_password_set ]; then
	echo "MongoDB password already set!"
	exit 0
fi

/usr/bin/mongod --smallfiles --nojournal &

ADMINPASS=${MONGODB_ADMIN_PASS:-$(pwgen -s 12 1)}
USERPASS=${MONGODB_USER_PASS:-$(pwgen -s 12 1)}

_word=$( [ ${MONGODB_ADMIN_PASS} ] && echo "preset" || echo "random" )
_word2=$( [ ${MONGODB_USER_PASS} ] && echo "preset" || echo "random" )

RET=1
while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MongoDB service startup"
    sleep 5
    mongo admin --eval "help" >/dev/null 2>&1
    RET=$?
done

sleep 5

echo "=> Creating an admin user with a ${_word} password in MongoDB"
mongo admin --eval "db.addUser({ user: 'admin', pwd: '$ADMINPASS', roles: [ { role: 'root', db: 'admin' }, { role: 'userAdminAnyDatabase', db: 'admin }, { role: 'dbAdminAnyDatabase', db: 'admin' } ] });"
sleep 5

echo "=> Creating an regular user with a ${_word2} password in MongoDB"
mongo admin --eval "db.addUser({ user: 'user', pwd: '$USERPASS', roles: [ { role: 'readWriteAnyDatabase', db: 'admin' } ] });"
sleep 5

mongo admin --eval "db.shutdownServer();"
sleep 5

echo "=> Done!"
touch /.mongodb_password_set

echo "========================================================================"
echo "You can now connect to this MongoDB server using:"
echo ""
echo "    mongo admin -u admin -p $ADMINPASS --host <host> --port <port>"
echo ""
echo "or"
echo ""
echo "    mongo admin -u user -p $USERPASS --host <host> --port <port>"
echo ""
echo "Please remember to change the above password as soon as possible!"
echo "========================================================================"

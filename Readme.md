retrieve stats from asterisk cdr database

installation instruction for ubuntu 12.04:

----

# apt-get install asterisk asterisk-mysql mysql-server
# nano /etc/asterisk/modules.conf

[global]
load => cdr_addon_mysql.so

# nano /etc/asterisk/cdr.conf

[mysql_connection]
connection=asterisk_mysql
table=cdr

# nano /etc/asterisk/cdr_mysql.conf

[global]
hostname=localhost
dbname=asteriskcdrdb
table=cdrs
password=__PASSWORD__
user=__USER__
;port=3306
sock=/var/run/mysqld/mysqld.sock
timezone=UTC ; Previously called usegmtime

# mysql -u root -p

CREATE database asteriskcdrdb;

USE asteriskcdrdb;

CREATE TABLE cdrs (
    id int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
        calldate datetime NOT NULL default '0000-00-00 00:00:00',
        clid varchar(80) NOT NULL default '',
        src varchar(80) NOT NULL default '',
        dst varchar(80) NOT NULL default '',
        dcontext varchar(80) NOT NULL default '',
        channel varchar(80) NOT NULL default '',
        dstchannel varchar(80) NOT NULL default '',
        lastapp varchar(80) NOT NULL default '',
        lastdata varchar(80) NOT NULL default '',
        duration int(11) NOT NULL default '0',
        billsec int(11) NOT NULL default '0',
        disposition varchar(45) NOT NULL default '',
        amaflags int(11) NOT NULL default '0',
        accountcode varchar(20) NOT NULL default '',
        uniqueid varchar(32) NOT NULL default '',
        userfield varchar(255) NOT NULL default '',
        peeraccount varchar(20) NOT NULL default '',
        linkedid varchar(32) NOT NULL default '',
        sequence int(11) NOT NULL default '0'
);


# asterisk -rvvvvvvvvvvvvvv

cdr show status
module show like mysql

----

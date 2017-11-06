
======
Galera
======

Galera Cluster for MySQL is a true Multimaster Cluster based on synchronous replication. Galera Cluster is an easy-to-use, high-availability solution, which provides high system uptime, no data loss and scalability for future growth.

Sample pillars
==============

Galera cluster master node

.. code-block:: yaml

    galera:
      version:
        mysql: 5.6
        galera: 3
      master:
        enabled: true
        name: openstack
        bind:
          address: 192.168.0.1
          port: 3306
        members:
        - host: 192.168.0.1
          port: 4567
        - host: 192.168.0.2
          port: 4567
        admin:
          user: root
          password: pass
        database:
          name:
            encoding: 'utf8'
            users:
            - name: 'username'
              password: 'password'
              host: 'localhost'
              rights: 'all privileges'

Galera cluster slave node

.. code-block:: yaml

    galera:
      slave:
        enabled: true
        name: openstack
        bind:
          address: 192.168.0.2
          port: 3306
        members:
        - host: 192.168.0.1
          port: 4567
        - host: 192.168.0.2
          port: 4567
        admin:
          user: root
          password: pass

Enable TLS support:

.. code-block:: yaml

    galera:
       slave or master:
         ssl:
          enabled: True

          # path
          cert_file: /etc/mysql/ssl/cert.pem
          key_file: /etc/mysql/ssl/key.pem
          ca_file: /etc/mysql/ssl/ca.pem

          # content (not required if files already exists)
          key: << body of key >>
          cert: << body of cert >>
          cacert_chain: << body of ca certs chain >>


Additional mysql users:

.. code-block:: yaml

    mysql:
      server:
        users:
          - name: clustercheck
            password: clustercheck
            database: '*.*'
            grants: PROCESS
          - name: inspector
            host: 127.0.0.1
            password: password
            databases:
              mydb:
                - database: mydb
                - table: mytable
                - grant_option: True
                - grants:
                  - all privileges

Additional check params:
========================

.. code-block:: yaml

    galera:
      clustercheck:
        - enabled: True
        - user: clustercheck
        - password: clustercheck
        - available_when_donor: 0
        - available_when_readonly: 1
        - port 9200

Configurable soft parameters
============================


- **galera_innodb_buffer_pool_size** - the default value is 3138M
- **galera_max_connections** - the default value is 20000

Usage:
.. code-block:: yaml

    _param:
      galera_innodb_buffer_pool_size: 1024M
      galera_max_connections: 200


Usage
=====

MySQL Galera check sripts

.. code-block:: bash

    mysql> SHOW STATUS LIKE 'wsrep%';

    mysql> SHOW STATUS LIKE 'wsrep_cluster_size' ;"

Galera monitoring command, performed from extra server

.. code-block:: bash

    garbd -a gcomm://ipaddrofone:4567 -g my_wsrep_cluster -l /tmp/1.out -d

1. salt-call state.sls mysql
2. Comment everything starting wsrep* (wsrep_provider, wsrep_cluster, wsrep_sst)
3. service mysql start
4. run on each node mysql_secure_install and filling root password.

.. code-block:: bash

    Enter current password for root (enter for none):
    OK, successfully used password, moving on...

    Setting the root password ensures that nobody can log into the MySQL
    root user without the proper authorisation.

    Set root password? [Y/n] y
    New password:
    Re-enter new password:
    Password updated successfully!
    Reloading privilege tables..
     ... Success!

    By default, a MySQL installation has an anonymous user, allowing anyone
    to log into MySQL without having to have a user account created for
    them.  This is intended only for testing, and to make the installation
    go a bit smoother.  You should remove them before moving into a
    production environment.

    Remove anonymous users? [Y/n] y
     ... Success!

    Normally, root should only be allowed to connect from 'localhost'.  This
    ensures that someone cannot guess at the root password from the network.

    Disallow root login remotely? [Y/n] n
     ... skipping.

    By default, MySQL comes with a database named 'test' that anyone can
    access.  This is also intended only for testing, and should be removed
    before moving into a production environment.

    Remove test database and access to it? [Y/n] y
     - Dropping test database...
     ... Success!
     - Removing privileges on test database...
     ... Success!

    Reloading the privilege tables will ensure that all changes made so far
    will take effect immediately.

    Reload privilege tables now? [Y/n] y
     ... Success!

    Cleaning up...

5. service mysql stop
6. uncomment all wsrep* lines except first server, where leave only in my.cnf wsrep_cluster_address='gcomm://';
7. start first node
8. Start third node which is connected to first one
9. Start second node which is connected to third one
10. After starting cluster, it must be change cluster address at first starting node without restart database and change config my.cnf.

.. code-block:: bash

    mysql> SET GLOBAL wsrep_cluster_address='gcomm://10.0.0.2';

Read more
=========

* https://github.com/CaptTofu/ansible-galera
* http://www.sebastien-han.fr/blog/2012/04/15/active-passive-failover-cluster-on-a-mysql-galera-cluster-with-haproxy-lsb-agent/
* http://opentodo.net/2012/12/mysql-multi-master-replication-with-galera/
* http://www.codership.com/wiki/doku.php
* Best one: - http://www.sebastien-han.fr/blog/2012/04/01/mysql-multi-master-replication-with-galera/

Documentation and Bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-galera/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-galera

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net

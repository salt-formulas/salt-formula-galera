
=====
Usage
=====

Galera Cluster for MySQL is a true Multimaster Cluster based on synchronous
replication. Galera Cluster is an easy-to-use, high-availability solution,
which provides high system uptime, no data loss and scalability for future
growth.

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

Additional mysql SSL grants:

.. code-block:: yaml

    mysql:
      server:
        users:
          - name: clustercheck
            password: clustercheck
            database: '*.*'
            grants: PROCESS
            ssl_option:
              - SSL: True
              - X509: True
              - SUBJECT: <subject>
              - ISSUER: <issuer>
              - CIPHER: <cipher>

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

- ``galera_innodb_buffer_pool_size``
   Default is ``3138M``
- ``galera_max_connections``
   Default is ``20000``
- ``galera_innodb_read_io_threads``
   Default is ``8``
- ``galera_innodb_write_io_threads``
   Default is ``8``
- ``galera_wsrep_slave_threads``
   Default is ``8``
- ``galera_xtrabackup_parallel``
   Default is 4
- ``galera_error_log_enabled``
   Default is ``false``

Usage:

.. code-block:: yaml

    _param:
      galera_innodb_buffer_pool_size: 1024M
      galera_max_connections: 200
      galera_innodb_read_io_threads: 16
      galera_innodb_write_io_threads: 16
      galera_wsrep_slave_threads: 8
      galera_xtrabackup_parallel: 2
      galera_error_log_enabled: true

Usage
=====

MySQL Galera check sripts

.. code-block:: bash

    mysql> SHOW STATUS LIKE 'wsrep%';

    mysql> SHOW STATUS LIKE 'wsrep_cluster_size' ;"

Galera monitoring command, performed from extra server

.. code-block:: bash

    garbd -a gcomm://ipaddrofone:4567 -g my_wsrep_cluster -l /tmp/1.out -d

#. salt-call state.sls mysql
#. Comment everything starting wsrep* (wsrep_provider, wsrep_cluster, wsrep_sst)
#. service mysql start
#. run on each node mysql_secure_install and filling root password.

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

#. service mysql stop
#. uncomment all wsrep* lines except first server, where leave only in
   my.cnf wsrep_cluster_address='gcomm://';
#. start first node
#. Start third node which is connected to first one
#. Start second node which is connected to third one
#. After starting cluster, it must be change cluster address at first starting node
   without restart database and change config my.cnf.

   .. code-block:: bash

      mysql> SET GLOBAL wsrep_cluster_address='gcomm://10.0.0.2';

Read more
=========

* https://github.com/CaptTofu/ansible-galera
* http://www.sebastien-han.fr/blog/2012/04/15/active-passive-failover-cluster-on-a-mysql-galera-cluster-with-haproxy-lsb-agent/
* http://opentodo.net/2012/12/mysql-multi-master-replication-with-galera/
* http://www.codership.com/wiki/doku.php
* http://www.sebastien-han.fr/blog/2012/04/01/mysql-multi-master-replication-with-galera/

Documentation and bugs
======================

* http://salt-formulas.readthedocs.io/
   Learn how to install and update salt-formulas

*  https://github.com/salt-formulas/salt-formula-galera/issues
   In the unfortunate event that bugs are discovered, report the issue to the
   appropriate issue tracker. Use the Github issue tracker for a specific salt
   formula

* https://launchpad.net/salt-formulas
   For feature requests, bug reports, or blueprints affecting the entire
   ecosystem, use the Launchpad salt-formulas project

* https://launchpad.net/~salt-formulas-users
   Join the salt-formulas-users team and subscribe to mailing list if required

* https://github.com/salt-formulas/salt-formula-galera
   Develop the salt-formulas projects in the master branch and then submit pull
   requests against a specific formula

* #salt-formulas @ irc.freenode.net
   Use this IRC channel in case of any questions or feedback which is always
   welcome


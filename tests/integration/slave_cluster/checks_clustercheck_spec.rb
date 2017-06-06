describe file('/etc/xinetd.d/mysql_clustercheck.conf') do
    it('should exist')
    its('content') { should match /clustercheck clustercheck password 1 1/ }
end

describe file('/usr/local/bin/mysql_clustercheck') do
    it('should exist')
end

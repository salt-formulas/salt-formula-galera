describe file('/etc/xinetd.d/mysql_clustercheck_9200') do
    it('should exist')
    its('content') { should match /clustercheck password clustercheck 1 1/ }
end

describe file('/usr/local/bin/mysql_clustercheck') do
    it('should exist')
end

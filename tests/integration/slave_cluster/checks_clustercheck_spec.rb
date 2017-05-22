describe file('/etc/xinetd.d/mysql_clustercheck') do
    it('should exist')
    its('content') { should match /server.*\/usr\/local\/bin\/mysql_clustercheck/ }
    its('content') { should match /server_args.*clustercheck password available_when_donor=1 \/dev\/null available_when_readonly=1/ }
end

describe file('/usr/local/bin/mysql_clustercheck') do
    it('should exist')
    it('should be_executable')
end

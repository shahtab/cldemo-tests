require 'spec_helper'

for dirname in ['/mr-history', '/mr-history/tmp', '/mr-history/done', '/app-logs'] do
  describe command('hdfs dfs -test -e ' + dirname) do
    its(:exit_status) { should eq 0 }
  end
end

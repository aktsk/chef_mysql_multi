my_cnf = '/etc/my.cnf'

node['mysql_multi']['instances'].each.with_index do |conf|
  mysql_service node['mysql']['service_name'] do
    data_dir "/var/lib/#{conf['base']}"
    not_if { File.exists?("/var/lib/#{conf['base']}") }
  end
end

template "/tmp/my_cnf_mysqld_multi" do
  source "mysql-multi.cnf.erb"
end

ruby_block "remove-mysqld_multi-in-my-cnf" do
  block do
    text = File.read('/etc/my.cnf')
    File.write('/etc/my.cnf', text.gsub(/\n*\[mysqld_multi\].*?(\[|\Z)/m, '%s\1' % ["\n"]))
  end
end

execute 'append-mysql_multi-to-my-cnf' do
  command "cat /tmp/my_cnf_mysqld_multi >> #{my_cnf}; rm /tmp/my_cnf_mysqld_multi"
  action :run
end

node['mysql_multi']['instances'].each do |conf|
  ruby_block "remove-mysqld_service-in-my-cnf" do
    block do
      text = File.read('/etc/my.cnf')
      File.write('/etc/my.cnf', text.gsub(/\n*\[#{conf['service']}\].*?(\[|\Z)/m, '%s\1' % ["\n"]))
    end
  end

  template "/tmp/mysql-multi-instance.cnf" do
    variables(
      :base => conf['base'],
      :service => conf['service'],
      :port => conf['port'],
      :server_id => conf['server_id'],
    )
    source "mysql-multi-instance.cnf.erb"
  end

  execute 'append-mysql_multi_instance-to-my-cnf' do
    command "cat /tmp/mysql-multi-instance.cnf >> #{my_cnf}; rm /tmp/mysql-multi-instance.cnf"
    action :run
  end
end

directory "/var/log/mysql" do
  owner "mysql"
  group "mysql"
  mode 00755
  action :create
end

directory "/var/log/mysql/binlog" do
  owner "mysql"
  group "mysql"
  mode 00750
  action :create
end

service 'mysqld' do
  action [:stop, :disable]
end

execute 'start-mysqld-multi-instances' do
  command "mysqld_multi start"
  action :run
end

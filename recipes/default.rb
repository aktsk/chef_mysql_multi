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

node['mysql_multi']['instances'].each do |conf|
  socket_file = "/var/lib/#{conf['base']}/mysql.sock"

  execute 'wait for mysql' do
    command "until [ -S #{socket_file} ] ; do sleep 1 ; done"
    timeout 20
    action :run
  end

  if node['mysql']['server_root_password'].empty?
    pass_string = ''
  else
    pass_string = "-p#{node['mysql']['server_root_password']}"
  end

  execute 'install-grants' do
    cmd = "mysql -S #{socket_file} -u root "
    cmd << "#{pass_string} < /etc/mysql_grants.sql"
    command cmd
    action :nothing
  end

  execute 'assign-root-password' do
    cmd = "mysqladmin -S #{socket_file} -u root password "
    cmd << node['mysql']['server_root_password']
    command cmd
    action :run
    only_if "mysql -S #{socket_file} -u root -e 'show databases;'"
  end
end

my_cnf = '/etc/my.cnf'
return unless File.exists?(my_cnf)

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

node['mysql_multi'].each.with_index do |conf|
  base = conf['base']

  mysql_service node['mysql']['service_name'] do
    data_dir "/var/lib/#{base}"
    not_if { File.exists?("/var/lib/#{base}") }
  end
end

template "/tmp/my_cnf_mysqld_multi" do
  source "mysql-multi.cnf.erb"
end

ruby_block "remove-mysqld_multi-in-my-cnf" do
  block do
    text = File.read(my_cnf)
    File.write(my_cnf, text.gsub(/^\[mysqld_multi\].*?(\[|\Z)/m, '\1'))
  end
end

execute 'append-mysql_multi-to-my-cnf' do
  cmd = "cat /tmp/my_cnf_mysqld_multi >> #{my_cnf} && rm /tmp/my_cnf_mysqld_multi"
  command cmd
  action :run
end

node['mysql_multi'].each.with_index do |conf, index|
  base = conf['base']
  template "/tmp/mysql-multi-instance.cnf" do
    variables(
      :base => base,
      :service => conf['service'],
      :port => conf['port'],
      :server_id => conf['server_id'],
    )
    source "mysql-multi-instance.cnf.erb"
  end

  text = File.read(my_cnf)
  File.write(my_cnf, text.gsub(/^\[#{base}\].*?(\[|\Z)/m, '\1'))

  execute 'append-mysql_multi_instance-to-my-cnf' do
    cmd = "cat /tmp/mysql-multi-instance.cnf >> #{my_cnf} && rm /tmp/mysql-multi-instance.cnf"
    command cmd
    action :run
  end
end

service 'mysqld' do
  action [:stop, :disable]
end

execute 'start-mysqld-multi-instances' do
  command "mysqld_multi start"
  action :run
end

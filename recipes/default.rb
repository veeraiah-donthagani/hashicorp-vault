#
# Cookbook: hashicorp-vault
# License: Apache 2.0
#
# Copyright 2015-2016, Bloomberg Finance L.P.
#
poise_service_user node['hashicorp-vault']['service_user'] do
  group node['hashicorp-vault']['service_group']
  not_if { node['hashicorp-vault']['service_user'] == 'root' }
end

install = vault_installation node['hashicorp-vault']['version'] do |r|
  if node['hashicorp-vault']['installation']
    node['hashicorp-vault']['installation'].each_pair { |k, v| r.send(k, v) }
  end
end

config = vault_config node['hashicorp-vault']['config']['path'] do |r|
  owner node['hashicorp-vault']['service_user']
  group node['hashicorp-vault']['service_group']

  if node['hashicorp-vault']['config']
    node['hashicorp-vault']['config'].each_pair { |k, v| r.send(k, v) }
  end
  notifies :reload, "vault_service[#{node['hashicorp-vault']['service_name']}]", :delayed
end

vault_service node['hashicorp-vault']['service_name'] do |r|
  user node['hashicorp-vault']['service_user']
  group node['hashicorp-vault']['service_group']
  config_path node['hashicorp-vault']['config']['path']
  disable_mlock config.disable_mlock
  ui config.ui    #newly added for ui
  program install.vault_program

  if node['hashicorp-vault']['service']
    node['hashicorp-vault']['service'].each_pair { |k, v| r.send(k, v) }
  end
  action [:enable, :start]
end

bash "append_to_config" do
   user "root"
   code <<-EOH
      echo 'export PATH=\"\$PATH:/usr/local/bin\"' >> /etc/profile
      echo 'export PATH=\"\$PATH:/usr/local/bin\"' >> ~/.bashrc
      source /etc/profile
      source ~/.bashrc
   EOH
   not_if "grep 'export PATH=\"$PATH:/usr/local/bin\"' /etc/profile"
 end

require 'chef/search/query'
require 'mysql'

describe 'mysql cluster' do
  # Boilerplate helpers
  def search_nodes(query)
    Search::Query.new.search(:node, query)
  end
  def ip_addresses(nodes)
    nodes.map { node['public_ip_address'] }
  end
  def connect(ip_address)
    Mysql.connect(ip_address, 'username', 'password', 'user')
  end
  let(:mysql_master) { ip_addresses(search_nodes('role:mysql_master'))[0] }
  let(:mysql_slaves) { ip_addresses(search_nodes('role:mysql_slave')) }

  it 'Writes to the master are reflected in the slaves' do
    master = connect(mysql_master)
    master.execute('create table x (y int)')
    master.execute('insert into x values (10)')
    expect( master.query('select y from x').to_a ).to == [ [ 10 ] ]

    mysql_slaves.each do |mysql_slave|
      expect( connect(mysql_slave).query('select y from x'.to_a ).to == [ [ 10 ] ]
    end
  end

  # TODO add failure test: bring down master and see if cluster still functions
end

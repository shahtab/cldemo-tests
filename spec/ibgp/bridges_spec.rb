require 'spec_helper'
require 'json'

# Bridges only exist on the leafs
if leaf?
  node_data = JSON.parse(File.read(File.expand_path('../data/bridges.json', __FILE__)))

  # Select the data that's specific to this node
  target_data = node_data[target]
  bridges = target_data[topology]['bridges']

  # Each bridge a) should exist b) should have each specified interface
  # The bridge configuration is the same on both leafs
  bridges.each do |br|
    describe bridge(br['name']) do
      it { should exist }
    end

    br['interfaces'].each do |intf|
      describe bridge(br['name']) do
        it { should have_interface(intf) }
      end
    end
  end
end

#
# Copyright 2012, Rackspace Hosting
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: Ron Pedde <ron@pedde.com>
#

# Inspiration: Andi Abes
# FIXME: Put proper credit and pointer to the Dell CloudEdge repo here...


# attribute :name,                   :kind_of => String
# attribute :owner,                  :kind_of => String
# attribute :group,                  :kind_of => String
# attribute :mode,                   :kind_of => String
# attribute :ring_path,              :kind_of => String


def load_current_resource
  # need to load and parse the existing rings.
  ring_path = @new_resource.ring_path
  ring_data = { :raw => {}, :parsed => {} }


  [ "account", "container", "object" ].each do |which|
    ring_data[:raw][which] = nil

    if ::File.exist?("#{ring_path}/#{which}.builder")
      IO.popen("swift-ring-builder #{ring_path}/#{which}.builder") do |pipe|
        ring_data[:raw][which] = pipe.readlines
        Chef::Log.info("#{ which.capitalize } Ring data: #{ring_data[:raw][which]}")
        ring_data[:parsed][which] = parse_ring_output(ring_data[:raw][which])

        node[:swift][:state] ||= {}
        node[:swift][:state][:ring] ||= {}
        node[:swift][:state][:ring][which] = ring_data[:parsed][which]
      end
    else
      Chef::Log.info("#{ which.capitalize } ring builder files do not exist")
    end
  end
end

# Parse the raw output of swift-ring-builder
def parse_ring_output(ring_data)
  output = { :state => {} }

  ring_data.each do |line|
    if line =~ /build version ([0-9]+)/
      output[:build_version] = $1
    elsif line =~ /^\s+(\d+)\s+(\d+)\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+)\s+(\S+)\s+([0-9.]+)\s+(\d+)\s+([-0-9.]+)\s*$/
      output[:hosts] ||= {}
      output[:hosts][$3] ||= {}

      output[:hosts][$3][:id] = $1
      output[:hosts][$3][:zone] = $2
      output[:hosts][$3][:ip] = $3
      output[:hosts][$3][:port] = $4
      output[:hosts][$3][:device] = $5
      output[:hosts][$3][:weight] = $6
      output[:hosts][$3][:partitions] = $7
      output[:hosts][$3][:balance] = $8
    elsif line =~ /(\d+) partitions, (\d+) replicas, (\d+) zones, (\d+) devices, ([\-0-9.]+) balance$/
      output[:state][:partitions] = $1
      output[:state][:replicas] = $2
      output[:state][:zones] = $3
      output[:state][:devices] = $4
      output[:state][:balance] = $5
    elsif line =~ /^The minimum number of hours before a partition can be reassigned is (\d+)$/
      output[:state][:min_part_hours] = $1
    else
      raise "Cannot parse ring builder output for #{line}"
    end
  end

  output
end

action :ensure_exists do
  Chef::Log.info("Ensuring #{@new_resource.name}")
end

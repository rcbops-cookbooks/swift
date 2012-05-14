#
# Cookbook Name:: swift
# Recipe:: swift-common
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

module Attributes
  def initialize()
    @attrs = nil
  end

  def get_pkg(name)
    if @attrs["packages"][name].class == String
      [@attrs["packages"][name]]
    else
      @attrs["packages"][name]
    end
  end

  def get_svc(name)
    "#{@attrs['service_prefix']}#{name}#{@attrs['service_suffix']}"
  end

  def get_attrs(where)
    retval = {}

    return {} unless node.has_key?(where) and node[where].has_key?("attributes")

    location_list = ["default",
                     node["platform"],
                     node["platform"] + "-" + node["platform_version"]]

    # merge up all the attributes
    location_list.each do |location|
      if node[where]["attributes"].has_key?(location)
        retval = retval.merge(node[where]["attributes"][location])
      end
    end

    classes = retval.inject({}){ |hsh, (k,v)| (hsh.merge(k => v) if k[/_class$/]) or hsh }

    classes.each do |k,v|
      retval.delete(k)
      obj = Kernel
      v.split("::").each do |klass|
        obj = obj.const_get(klass)
      end
      retval[k.gsub("_class","")] = obj
    end

    @attrs = retval
  end
end

module Babushka
  class SystemSpec
    include Shell::Helpers
    extend Shell::Helpers

    attr_reader :version_info

    def self.for_system
      self.for({
        'Linux' => :linux,
        'Darwin' => :osx
      }[shell 'uname -s'])
    end

    def self.for uname_info
      system_map[uname_info].new
    end

    def initialize
      @version_info = get_version_info
    end

    def linux?; false end
    def osx?; false end

    def name
      (name_map[system][flavour] || {})[release]
    end
    def name_str
      (name_str_map[system][flavour] || {})[release]
    end

    def match_list
      [name, flavour, system, :all]
    end

    def matches? specs
      [*specs].any? {|spec| first_nonmatch_for(spec).nil? }
    end

    def first_nonmatch_for spec
      if spec == :all
        nil
      elsif spec.in? all_systems
        spec == system ? nil : :system
      elsif spec.in? our_flavours
        spec == flavour ? nil : :flavour
      elsif spec.in? our_flavour_names
        spec == name ? nil : :name
      else
        :system
      end
    end

    def differentiator_for specs
      nonmatches = [*specs].map {|spec|
        first_nonmatch_for spec
      }.sort_by {|spec|
        [:system, :flavour, :name].index spec
      }.compact
      send "#{nonmatches.last}_str" unless nonmatches.empty?
    end

    def self.system_map
      {
        :osx => OSXSystemSpec,
        :linux => LinuxSystemSpec
      }
    end

    def all_systems
      name_map.keys
    end
    def all_flavours
      name_map.values.map(&:keys).flatten
    end
    def all_names
      name_map.values.map(&:values).map {|s| s.map(&:values) }.flatten
    end
    def our_flavours
      name_map[system].keys
    end
    def our_flavour_names
      name_map[system][flavour].values
    end
    def all_tokens
      all_systems + all_flavours + all_names
    end

    def name_map
      {
        :osx => {
          :osx => {
            '10.3' => :panther,
            '10.4' => :tiger,
            '10.5' => :leopard,
            '10.6' => :snow_leopard
          }
        },
        :linux => {
          :ubuntu => {
            '4.10'  => :warty,
            '5.04'  => :hoary,
            '5.10'  => :breezy,
            '6.06'  => :dapper,
            '6.10'  => :edgy,
            '7.04'  => :feisty,
            '7.10'  => :gutsy,
            '8.04'  => :hardy,
            '8.10'  => :intrepid,
            '9.04'  => :jaunty,
            '9.10'  => :karmic,
            '10.04' => :lucid
          },
          :debian => {
            '5.0.4' => :lenny
          }
        }
      }
    end
    def name_str_map
      {
        :osx => {
          :osx => {
            '10.3' => 'Panther',
            '10.4' => 'Tiger',
            '10.5' => 'Leopard',
            '10.6' => 'Snow Leopard'
          }
        },
        :linux => {
          :ubuntu => {
            '4.10'  => 'Warty Warthog',
            '5.04'  => 'Hoary Hedgehog',
            '5.10'  => 'Breezy Badger',
            '6.06'  => 'Dapper Drake',
            '6.10'  => 'Edgy Eft',
            '7.04'  => 'Feisty Fawn',
            '7.10'  => 'Gutsy Gibbon',
            '8.04'  => 'Hardy Heron',
            '8.10'  => 'Intrepid Ibex',
            '9.04'  => 'Jaunty Jackalope',
            '9.10'  => 'Karmic Koala',
            '10.04' => 'Lucid Lynx'
          },
          :debian => {
            '5.0.4' => 'Lenny'
          }
        }
      }
    end

  end

  class OSXSystemSpec < SystemSpec
    def osx?; true end
    def system; :osx end
    def system_str; 'Mac OS X' end
    def flavour; system end
    def flavour_str; system_str end
    def version; version_info.val_for 'ProductVersion' end
    def release; version.match(/^\d+\.\d+/).to_s end
    def get_version_info; shell 'sw_vers' end
  end
  
  class LinuxSystemSpec < SystemSpec
    def linux?; true end
    def system; :linux end
    def system_str; 'Linux' end
    def flavour; flavour_str.downcase.to_sym end
    def flavour_str; version_info.val_for 'Distributor ID' end
    def version; version_info.val_for 'Release' end
    def release; version end
    def get_version_info; shell 'lsb_release -a' end
  end
end

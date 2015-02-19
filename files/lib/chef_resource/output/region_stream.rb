module ChefResource
  module Chef
    module Output
      class RegionText

      end

      #
      # A region of the screen.
      #
      class ScreenRegion
        def initialize(parent)
          @parent = parent
          @width = 0
          @height = 0
        end

        #
        # The parent region
        #
        property :parent

        #
        # The top y coordinate of the region
        #
        property :top

        #
        # The left hand coordinate of the region
        #
        property :height

        #
        # The width of the region.
        #
        property :width

        #
        # The height of the region
        #
        property :height
      end

      #
      # A list of regions
      #
      class ScreenRegionList < ScreenRegion
        def regions
          @regions ||= []
        end
        def add_region(region)
          regions << region if !regions.include?(region)
        end
        def remove_region(region)
          regions.delete(region)
        end
      end

      #
      # A horizontal list of regions
      #
      class HorizontalRegionList < ScreenRegionList
      end

      #
      # A vertical list of regions
      #
      class VerticalRegionList
      end

      #
      # A nested display like so:
      #
      # cookbook::recipe_name
      # |-- Machine Batch: web
      # |   |-- Machine web1
      # |   |   |-- Node web1
      # |   |   |   |-- Property apache2.port changed from 80 to 8080
      # |   |-- Machine web2 - Updated
      # |-- Header3
      # |-- Header4
      #
      # In the future, we may even switch it out so you can expand or collapse.
      #
      # A single ChildrenTree has these regions:
      #
      # |---------------------------------------|
      # | Gutter | Sub-Region                   |
      # |        |                              |
      # |        |------------------------------|
      # |        | Sub-Region                   |
      # |        |                              |
      # |        |------------------------------|
      # |        | Sub-Region                   |
      # |        |                              |
      # |--------|------------------------------|

      class ChildrenTree < ScreenRegionList
        def initialize(parent)
          @parent = parent
          parent.add_region(self) if parent.is_a?(ScreenRegionList)
        end

        def height
          gutter.height
        end

        attr_reader :parent
        def children
          @children ||= []
        end

        def header
          @header ||= StreamRegion.new()
        end
      end

      #
      # Limits itself to a region of the screen, cutting off display on the right
      #
      # Splits up the screen like this:
      #
      class RegionStream < ScreenRegion
        attr_accessor :width
        attr_accessor :height
        attr_accessor :header_lines
        attr_accessor :lines
      end

      #
      # Prints lines like
      # [x.txt] updating ...
      #
      #
      class ParallelRegionStream < RegionStream
        attr_accessor :
      end
    end
  end
end

chef_run
  recipe x
    file /x/y/z.txt
      execute ls /x/y/z.txt

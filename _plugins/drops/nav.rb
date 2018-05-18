module Jekyll
  module Drops
    class Nav < Liquid::Drop

      def initialize(node)
        @node = node
        @node[:empty] = true
      end

      def item
        @node[:item]
      end

      def path
        @node[:path]
      end

      def children
        @node[:children]
      end

      def empty?
        @node[:empty]
      end

      def open?
        @node[:open]
      end

      def <<(child)
        @node[:children] << child
        @node[:empty] = false
      end
    end
  end
end

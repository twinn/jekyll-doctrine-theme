# coding: utf-8
require 'set'
require_relative 'drops/breadcrumb_item.rb'

module Jekyll
  module Breadcrumbs
    @@config = {}
    @@siteAddress = ""
    @@sideAddresses = {}

    def self.clearAddressCache
      @@sideAddresses = {}
    end

    def self.loadAddressCache(site)
      clearAddressCache
      site.documents.each { |page| addAddressItem(page.url, title_from_page(page), icon_from_page(page)) } # collection files including posts
      site.pages.each { |page| addAddressItem(page.url, title_from_page(page), icon_from_page(page)) } # pages
      site.posts.docs.each { |page| addAddressItem(page.url, title_from_page(page), icon_from_page(page)) } # posts
    end

    def self.title_from_page(page)
      page['crumbtitle'] || page['title'] || page['name'].capitalize || ''
    end

    def self.icon_from_page(page)
      page['icon'] || "📄"
    end

    def self.addAddressItem(url, title, icon)
      key = createAddressCacheKey(url)
      @@sideAddresses[key] = {:url => url.chomp(".index"), :title => title, :icon => icon}
    end

    def self.findAddressItem(path)
      key = createAddressCacheKey(path)
      @@sideAddresses[key] if key
    end

    def self.createAddressCacheKey(path)
      path.chomp("/").empty? ? "/" : path.chomp("/").chomp(".html")
    end

    def self.buildSideBreadcrumbs(side, payload)
      payload["breadcrumbs"] = []
      return if side.url == @@siteAddress && root_hide === true

      drop = Jekyll::Drops::BreadcrumbItem
      position = 0

      path = side.url.chomp("/").split(/(?=\/)/)
      -1.upto(path.size - 1) do |int|
         joined_path = int == -1 ? "" : path[0..int].join
         item = findAddressItem(joined_path)
         if item 
            position += 1
            item[:position] = position
            item[:root_image] = root_image
            payload["breadcrumbs"] << drop.new(item)
         end
      end
    end

    def self.open(parts, side_parts)
      parts.to_set.subset?(side_parts.to_set) ? "open" : ""
    end

    def self.get_parts(key)
      parts = key.split("/")
      parts.empty? ? [""] : parts
    end

    def self.build_nav(side, payload)
      side_parts = get_parts(side.url.chomp(".html"))

      payload["left_nav"] = @@sideAddresses.keys.sort.reduce({}) do |acc, key|
        parts = get_parts(key)
        details_open = open(parts, side_parts)
        item = findAddressItem(key)
        nav_item = Jekyll::Drops::Nav.new({open: details_open, path: key, item: Jekyll::Drops::BreadcrumbItem.new(item), children: []})

        add_item(acc, parts, nav_item)
      end
    end

    def self.get_path(parts, num)
      parts.take(num).join("/")
    end

    def self.find_index(item, parts, num)
      item.find_index { |c| c.path == get_path(parts, num)}
    end

    def self.add_item(acc, parts, nav_item)
      case parts.length
      when 1
        acc = nav_item
      when 2
        acc << nav_item
      when 3
        child_index = find_index(acc[:children], parts, 2)
        if child_index
          acc[:children][child_index] << nav_item
        end
      when 4
        child_index_1 = find_index(acc[:children], parts, 2)
        if child_index_1
          child_index_2 = find_index(acc[:children][child_index_1][:children], parts, 3)
        end
        if child_index_1 && child_index_2
          acc[:children][child_index_1][:children][child_index_2] << nav_item
        end
      end

      acc
    end

    def self.loadConfig(site)
       config = site.config["breadcrumbs"] || {"root" => {"hide" => false, "image" => false}} 
       root = config["root"]
       @@config[:root_hide] = root["hide"] || false
       @@config[:root_image] = root["image"] || false
       @@config[:show_nav] = true

       @@siteAddress = site.config["baseurl"] || "/"
       @@siteAddress = "/" if @@siteAddress.empty?
     end

     def self.root_hide
       @@config[:root_hide]
    end

    def self.root_image
       @@config[:root_image]
    end
  end
end

Jekyll::Hooks.register :site, :pre_render do |site, payload|
  Jekyll::Breadcrumbs::loadConfig(site)
  Jekyll::Breadcrumbs::loadAddressCache(site)
end

Jekyll::Hooks.register [:pages, :documents], :pre_render do |side, payload|
  Jekyll::Breadcrumbs::buildSideBreadcrumbs(side, payload)
  Jekyll::Breadcrumbs::build_nav(side, payload)
end

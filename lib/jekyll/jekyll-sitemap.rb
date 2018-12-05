# frozen_string_literal: true
require "fileutils"

module Jekyll
  class JekyllSitemap < Jekyll::Generator
    safe true
    priority :lowest

    # Main plugin action, called by Jekyll-core
    def generate(site)
      @site = site
      @site.pages << sitemap unless file_exists?(sitemap_file)
      @site.pages << robots unless file_exists?(robots_file)
    end

    private

    INCLUDED_EXTENSIONS = %w(
      .htm
      .html
      .xhtml
      .pdf
    ).freeze

    # Matches all whitespace that follows
    #   1. A '>' followed by a newline or
    #   2. A '}' which closes a Liquid tag
    # We will strip all of this whitespace to minify the template
    MINIFY_REGEX = %r!(?<=>\n|})\s+!.freeze

    # Array of all non-jekyll site files with an HTML extension
    def static_files
      @site.static_files.select { |file| INCLUDED_EXTENSIONS.include? file.extname }
    end

    # Path to sitemap.xml template file
    def source_path(file = "sitemap.xml")
      File.expand_path "../#{file}", __dir__
    end

    # Destination for sitemap.xml file within the site source directory
    def destination_path
      @site.in_dest_dir(sitemap_file)
    end

    def sitemap_file
      @site.config.dig('sitemap', 'filename') rescue 'sitemap.xml'
    end

    def robots_file
      "robots.txt"
    end

    def sitemap
      site_map = PageWithoutAFile.new(@site, __dir__, "", sitemap_file)
      site_map.content = File.read(source_path).gsub(MINIFY_REGEX, "")
      site_map.data["layout"] = nil
      site_map.data["static_files"] = static_files.map(&:to_liquid)
      site_map.data["xsl"] = file_exists?("#{File.basename(sitemap_file, '.*')}.xsl")
      site_map
    end

    def robots
      robots = PageWithoutAFile.new(@site, __dir__, "", robots_file)
      robots.content = File.read(source_path(robots_file))
      robots.data["layout"] = nil
      robots
    end

    # Checks if a file already exists in the site source
    def file_exists?(file_path)
      if @site.respond_to?(:in_source_dir)
        File.exist? @site.in_source_dir(file_path)
      else
        File.exist? Jekyll.sanitized_path(@site.source, file_path)
      end
    end
  end
end

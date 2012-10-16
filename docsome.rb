require 'rdiscount'
require 'digest/md5'
Camping.goes :Docsome

module Docsome::Controllers
  class Pages
    def get
      # only fetch the titles of the pages
      @pages = Page.all(:select => "title")
      render :list
    end
  end

  class PageX
    def get(title)
      if @page = Page.find_by_title(title)
        render :view
      else
        redirect PageXEdit, title
      end
    end

    def post(title)
      # if it doesn't exist, initialize it:
      @page = Page.find_or_initialize_by_title(title)
      # this is the same as:
      # @page = Page.find_by_title(title) || Page.new(:title => title)

      @page.content = @input.content
      @page.save
      redirect PageX, title
    end
  end

  class PageXEdit
    def get(title)
      @page = Page.find_or_initialize_by_title(title)
      render :edit
    end
  end

  class Style < R '/styles\.css'
    STYLE = File.read(__FILE__).gsub(/.*__END__/m, '')

    def get
      @headers['Content-Type'] = 'text/css; charset=utf-8'
      STYLE
    end
  end
end

module Docsome::Views
  def layout
    html do
      head do
        if @page.nil?
          title { "Docsome" }
        else
          title { "Docsome - #{@page.title}" }
        end

        link :rel => 'stylesheet', :type => 'text/css',
        :href => '/styles.css', :media => 'screen'
      end
    end
    body {
        self << yield
    }
  end

  def list
    h1 "All pages"
    ul do
      @pages.each do |page|
        li do
          a page.title, :href => R(PageX, page.title)
        end
      end
    end
  end

  def view
    h1 @page.title

    # Extract pre blocks
    # extractions = {}
    # text = RDiscount.new(@page.content).to_html
    # text.gsub!(%r{<pre>.*?</pre>}m) do |match|
    #   md5 = Digest::MD5.hexdigest(match)
    #   extractions[md5] = match
    #   "{gfm-extraction-#{md5}}"
    # end

    # # prevent foo_bar_baz from ending up with an italic word in the middle
    # text.gsub!(/(^(?! {4}|\t)\w+_\w+_\w[\w_]*)/) do |x|
    #   x.gsub('_', '\_') if x.split('').sort.to_s[0..1] == '__'
    # end

    # # in very clear cases, let newlines become <br /> tags
    # text.gsub!(/(\A|^$\n)(^\w[^\n]*\n)(^\w[^\n]*$)+/m) do |x|
    #   x.gsub(/^(.+)$/, "\\1  ")
    # end

    # # Insert pre block extractions
    # text.gsub!(/\{gfm-extraction-([0-9a-f]{32})\}/) do
    #   extractions[$1]
    # end

    self << RDiscount.new(@page.content).to_html
  end

  def edit
    h1 @page.title
    form :action => R(PageX, @page.title), :method => :post do
      textarea @page.content, :name => :content,
        :rows => 40, :cols => 190

      br

      input :type => :submit, :value => "Submit!"
    end
  end
end

module Docsome::Models
  class Page < Base
  end

  class BasicFields < V 1.0
    def self.up
      create_table Page.table_name do |t|
        t.string :title
        t.text   :content
        # this gives us created_at and updated_at
        t.timestamps
      end
    end

    def self.down
      drop_table Page.table_name
    end
  end
end

def Docsome.create
  Docsome::Models.create_schema
end

__END__

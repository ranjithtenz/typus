task :typus do
  system "rake -T typus --silent"
end

namespace :typus do

  desc "Create TypusUser `rake typus:seed email=foo@bar.com`"
  task :seed => :environment do

    include Authentication

    ##
    # Create the new user with the params.
    #
    email = ENV['email']
    password = ENV['password'] || generate_password

    begin
      typus_user = TypusUser.new(:email => email, 
                                 :password => password, 
                                 :password_confirmation => password, 
                                 :first_name => 'Typus', 
                                 :last_name => 'Admin', 
                                 :roles => 'admin', 
                                 :status => true)
      if typus_user.save
        puts "=> Your new password is `#{password}`."
      else
        puts "=> Please, provide a valid email. (rake typus:seed email=foo@bar.com)"
      end
    rescue
      puts "=> Run `script/generate typus_migration` to create required tables."
    end

  end

  desc "Install plugin dependencies"
  task :dependencies do

    ##
    # Plugins
    #
    plugins = [ "git://github.com/thoughtbot/paperclip.git", 
                "git://github.com/rails/acts_as_list.git", 
                "git://github.com/rails/acts_as_tree.git" ]

    plugins.each do |plugin_url|
      puts "=> Installing #{plugin_url}."
      system "script/plugin install #{plugin_url}"
    end

    ##
    # Gems
    #
    gems = [ "paginator" ]

    gems.each do |gem|
      puts "=> Installing #{gem}."
      # If command fails, please, notify user!
      if !(system "sudo gem install #{gem} --no-rdoc --no-ri")
        puts "Installing gem #{gem} failed: Error code returned was #{$?}."
      end
    end

  end

  desc "Copy Typus images and stylesheets"
  task :assets do
    puts "=> Copying images & stylesheets."
    %w( images stylesheets ).each do |folder|
      system "cp #{RAILS_ROOT}/vendor/plugins/typus/public/#{folder}/* #{RAILS_ROOT}/public/#{folder}/"
    end
  end

  desc "List current roles"
  task :roles => :environment do
    Typus::Configuration.roles.each do |role|
      puts "=> #{role.first.capitalize} has access to #{role.last.keys.join(", ")}."
    end
  end

  desc "Generate config/typus_roles.yml"
  task :configure_roles do
    begin
      MODEL_DIR = File.join(RAILS_ROOT, "app/models")
      Dir.chdir(MODEL_DIR)
      models = Dir["*.rb"]
      if !File.exists? ("#{RAILS_ROOT}/config/typus_roles.yml") or ENV['force']
        require File.dirname(__FILE__) + '/../../../../config/environment'
        typus = File.open("#{RAILS_ROOT}/config/typus_roles.yml", "w+")
        typus.puts "admin:"
        typus.puts "  TypusUser: crud"
        models.each do |model|
          class_name = eval model.sub(/\.rb$/,'').camelize
          if class_name.new.kind_of?(ActiveRecord::Base)
            typus.puts "  #{class_name}: crud"
          end
        end
        typus.close
        puts "=> `config/typus_roles.yml` successfully created."
      else
        puts "=> `config/typus_roles.yml` file already exists."
      end
    rescue Exception => e
      puts "#{e.message}"
      File.delete("#{RAILS_ROOT}/config/typus_roles.yml")
    end
  end

  desc "Generate config/typus.yml"
  task :configure do
    begin
      MODEL_DIR = File.join(RAILS_ROOT, "app/models")
      Dir.chdir(MODEL_DIR)
      models = Dir["*.rb"]
      ##
      # If typus config file does not file exists or force param is not blank, configure
      if !File.exists? ("#{RAILS_ROOT}/config/typus.yml") or ENV['force']
        require File.dirname(__FILE__) + '/../../../../config/environment'
        typus = File.open("#{RAILS_ROOT}/config/typus.yml", "w+")
        typus.puts "# ------------------------------------------------"
        typus.puts "# Typus Admin Configuration File"
        typus.puts "# ------------------------------------------------"
        typus.puts "#"
        typus.puts "# Post:"
        typus.puts "#   fields:"
        typus.puts "#     list: title, category_id, created_at, status"
        typus.puts "#     form: title, body, status, created_at"
        typus.puts "#     relationship: title, status"
        typus.puts "#   actions:"
        typus.puts "#     list: cleanup"
        typus.puts "#     form: send_as_newsletter"
        typus.puts "#   order_by: created_at"
        typus.puts "#   relationships:"
        typus.puts "#     has_and_belongs_to_many: "
        typus.puts "#     has_many: "
        typus.puts "#   filters: status, created_at, category_id"
        typus.puts "#   search: title body"
        typus.puts "#   application: Content"
        typus.puts "#   description: Some text to describe the model"
        typus.puts "#"
        typus.puts "# ------------------------------------------------"
        typus.puts ""
        typus.close
        models.each do |model|
          class_name = eval model.sub(/\.rb$/,'').camelize
          if class_name.new.kind_of?(ActiveRecord::Base)
            class_attributes = class_name.new.attributes.keys
            typus = File.open("#{RAILS_ROOT}/config/typus.yml", "a+")
            typus.puts ""
            typus.puts "#{class_name}:"
            list = class_attributes
            list.delete("content")
            list.delete("body")
            typus.puts "  fields:"
            typus.puts "    list: #{list.join(", ")}"
            typus.puts "    form: #{list.join(", ")}"
            typus.puts "    relationship: #{list.join(", ")}"
            typus.puts "  actions:"
            typus.puts "    list:"
            typus.puts "    form:"
            typus.puts "  order_by:"
            typus.puts "  relationships:"
            typus.puts "    has_and_belongs_to_many:"
            typus.puts "    has_many:"
            typus.puts "  filters:"
            typus.puts "  search:"
            typus.puts "  application: Untitled"
            typus.puts "  description:"
            typus.close
            puts "=> #{class_name} added to `config/typus.yml`"
          end
        end
      else
        puts "=> Configuration file already exists."
      end
    rescue Exception => e
      puts "#{e.message}"
      File.delete("#{RAILS_ROOT}/config/typus.yml")
    end
  end

  desc "Generate controllers"
  task :generate_controllers => :environment do
    Typus.generate_controllers
  end

end
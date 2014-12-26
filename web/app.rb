# KM Laser File Upload

require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/content_for'
require 'protected_attributes'
require 'haml'
require 'json'
require 'bcrypt'
require 'digest'
require 'time'

module Goldfinger
  class App < Sinatra::Base

    unless ARGV.size > 0 and ARGV[0].downcase == 'debug'
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
    end

    ###################
    # Config Settings #
    ###################

    configure do
      disable :method_override
      set :sessions,
          :httponly,
          :secret => ENV['SESSION_SECRET']
    end
    FILESTORE = File.join(File.expand_path(File.dirname(__FILE__)), 'files')
    FILESALT = BCrypt::Engine.generate_salt


    ###############
    # DB Settings #
    ###############

    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database:  'db/goldfinger.db'
    )


    ####################
    # Helper Functions #
    ####################

    def logged_in?
      @current_user != nil
    end

    set :auth do |*roles|
      condition do
        unless logged_in? && roles.any? {|role| @current_user.has_role? role }
        session.clear
        redirect "/login", 303
        end
      end
    end


    # Models
    # ======
    class User < ActiveRecord::Base
      attr_accessible :username, 
                      :password, 
                      :password_confirmation, 
                      :firstname, 
                      :lastname, 
                      :email

      attr_accessor :password
      attr_accessor :password_confirmation

      # Validations
      validates_confirmation_of :password
      validates_presence_of :username, :firstname, :lastname, :email
      validates_uniqueness_of :username

      # Relationships
      has_many :user_files

      before_save :encrypt_password, if: :password_changed?
      after_create :create_filestore

      def is_admin?
        self.admin
      end

      def has_role?(role)
        return true if role == :user
        puts "role != :user"
        return self.is_admin? if role == :admin
        puts "role != :admin"
        puts "role = #{role}"
        return false
      end

      def match_password(pw)
        self.password_hash == BCrypt::Engine.hash_secret(pw, self.password_salt)
      end

      def self.authenticate(username, pw)
        user = User.where(username: username).first
        if user and user.match_password(pw)
          user
        else
          nil
        end
      end

      def encrypt_password
        self.password_salt = BCrypt::Engine.generate_salt
        self.password_hash = BCrypt::Engine.hash_secret(password, password_salt)
      end

      def password_changed?
        !!self.password
      end

      def create_filestore
        fs_base = FILESTORE
        fs_path = File.join(fs_base, username)
        Dir.mkdir fs_path if !File.directory?(fs_path)
      end
    end

    class UserFile < ActiveRecord::Base
      attr_accessible :filename, :public
      belongs_to :user
      before_save :hash_filename

      # Validations
      validates_presence_of :filename

      def hash_filename
        self.filehash = Digest::MD5.hexdigest(filename + FILESALT)
      end

      def load_path
        "/files/#{self.filehash}/load"
      end

      def public_path
        "/files/#{self.filehash}/make_public"
      end

      def delete_path
        "/files/#{self.filehash}"
      end
    end
    
    class Post < ActiveRecord::Base
      belongs_to :user
      validates_presence_of :title, :message
    end


    before do
      begin
        @current_user = User.find(session[:user_id])
      rescue
        @current_user = nil
      end
    end

    after do
      ActiveRecord::Base.connection.close
    end

    # Routes
    # ======

    get '/', :auth => [:user] do
      @controller = 'index'
      @messages = Post.all.reverse_order.last(20)
      haml :index
    end

    get '/about', :auth => [:user] do
      @controller = 'about'
      haml :about
    end


    #######################
    # Login/Logout Routes #
    #######################

    get '/login' do
      haml :login
    end

    post '/login' do
      @current_user = User.authenticate(params['username'], params['password'])
      if @current_user and @current_user.active
        session[:user_id] = @current_user.id
        redirect '/'
      else
        puts "User #{params['username']} bad login"
        redirect "/login", 303
      end
    end

    get '/logout' do
      session.clear
      redirect '/login'
    end

    get '/register' do
      haml :register
    end

    post '/register' do
      u = User.new params[:user]
      if !u.save
        status 422
        {errors: u.errors.full_messages}.to_json
      else
        {message: "User Created Successfully"}.to_json
      end
    end

    ###############
    # User Routes #
    ###############

    get '/users', :auth => [:admin] do
      @users = User.all
      @controller = 'admin'
      haml :users
    end

    get '/users/new', :auth => [:admin] do
      @controller = 'admin'
      haml :users_new
    end

    #get '/users/:id/edit', :auth => [:admin] do
    #  @user = User.find(params[:id])
    #  haml :users_edit
    #end

    post '/users', :auth => [:admin] do
      new_user = User.new
      new_user.username = params['username']
      new_user.firstname = params['firstname']
      new_user.lastname = params['lastname']
      new_user.password = params['password']
      new_user.password_confirmation = params['password_confirmation']
      new_user.email = params['email']
      new_user.active = true
      new_user.admin = false
      new_user.save

      # this needs to be fixed, but just here for testing
      redirect '/admin'
      #return {success: true}.to_json
    end

    put '/users/:id', :auth => [:admin] do
      # update a user
    end

    put '/users/:id/activate', :auth => [:admin] do
      u = User.find(params[:id])
      u.active = true
      if !u.save
        status 422
        {errors: u.errors.full_messages}.to_json
      end
    end

    put '/users/:id/deactivate', :auth => [:admin] do
      u = User.find(params[:id])
      u.active = false
      if !u.save
        status 422
        {errors: u.errors.full_messages}.to_json
      end
    end

    put '/users/:id/active', :auth => [:admin] do
      active_status = params[:status]
      u = User.find(params[:id])
      u.active = active_status == 'true' ? true : false
      if !u.save
        status 422
        {errors: u.errors.full_messages}.to_json
      end
    end

    put '/users/:id/admin', :auth => [:admin] do
      admin_status = params[:status]
      u = User.find(params[:id])
      u.admin = admin_status == 'true' ? true : false
      if !u.save
        status 422
        {errors: u.errors.full_messages}.to_json
      end
    end

    delete '/users/:id', :auth => [:admin] do
      u = User.find(params[:id])
      if !u.destroy
        status 422
        {errors: u.errors.full_messages}.to_json
      end
    end

    get '/users/pw', :auth => [:user] do
      haml :changepw
    end

    post '/users/pw', :auth => [:user] do
      redirect '/'
    end

    get '/profile', :auth => [:user] do
      @controller = 'profile'
      haml :profile
    end

    # This method needs to be called with ajax and return success/failure
    post '/profile/changepw', :auth => [:user] do
      redirect '/profile' unless @current_user.match_password(params['oldpw'])

      @current_user.password = params['newpw']
      @current_user.password_confirmation = params['newpw_confirmation']
      @current_user.save

      redirect '/profile'
    end

    ###############
    # File Routes #
    ###############

    get '/files', :auth => [:user] do
      @controller = 'files'
      @files = @current_user.user_files.reverse_order
      @public = UserFile.where(public: true).where.not(user_id: @current_user.id).reverse_order
      haml :files
    end

    # This file really needs to return json
    post '/files', :auth => [:user] do
      uf = params[:userfile]
      redirect '/files' unless uf
      filename = uf[:filename]

      # Check filename and extension
      redirect '/files' unless filename =~ /\A\w*.ngc\z/
      # Check file using Unix File command
      redirect '/files' unless `file #{uf[:tempfile].path}` =~ /: ASCII text\n\z/

      filepath = File.join(FILESTORE,@current_user.username, filename)

      if !@current_user.user_files.find_by(filename: filename)
        f = UserFile.new
        f.filename = uf[:filename]
        f.filepath = filepath
        f.public = params[:public] ? true : false
        f.user = @current_user
        f.created_at = Time.now
        f.save
      end

      if File.directory?(File.join(FILESTORE, @current_user.username))
        File.open(filepath, "w") do |f|
          f.write(uf[:tempfile].read)
        end
      else
        puts "File was not able to be written. Dir doesn't exist"
      end

      redirect '/files'
    end

    post '/files/:hash/load', :auth => [:user] do
      retval = 'fail'
      msg = ''
      # Check if linuxcnc is running
      axis_up = system 'axis-remote -p'

      if axis_up
        # get file by hash
        f = UserFile.find_by(:filehash => params[:hash])

        # check if current user owns this file or
        # if file is public
        if f and (f.public or f.user_id == @current_user.id)
          # call axis_remote to load file
          rc = system "axis-remote #{f.filepath}"
          msg = rc ? "File loaded" : "ERROR while loading"
          loaded = rc ? true : false
        else
          # User is not allowed to load this file
          msg = "User is not allowed to load this file"
          loaded = false
        end
      else
        msg = 'LinuxCNC not currently running'
        loaded = false
      end
      if !loaded
        status 422
        retval = {errors: msg}.to_json
      else
        retval = {message: msg}.to_json
      end
    end

    post '/files/:hash/make_public', :auth => [:user] do
      f = @current_user.user_files.find_by(:filehash => params[:hash])
      if f
        f.public = true
        f.save
        {status: 'success', msg: f.public}.to_json
      else
        status 422
        {errors: "User does not have access or file doesn't exist"}.to_json
      end
    end

    delete '/files/:hash', :auth => [:user] do
      f = @current_user.user_files.find_by(:filehash => params[:hash])
      status = ''
      if f
        f.destroy
        {message: "File Destroyed!"}.to_json
      else
        status 422
        {errors: "File Does Not Exist. Can't be Deleted"}.to_json
      end
    end

    ##################
    # Command Routes #
    ##################

    get '/control', :auth => [:user] do
      @controller = 'control'
      haml :control
    end

    ################
    # Admin Routes #
    ################

    get '/admin', :auth => [:admin] do
      @controller = 'admin'
      @users = User.all
      haml :admin
    end

    get '/post_message', :auth => [:admin] do
      haml :post_message
    end
    
    post '/post_message', :auth => [:admin] do
      p = Post.new
      p.title = params[:title]
      p.message = params[:message]
      p.user_id = @current_user.id

      if p.save
        {message: 'Post Saved!'}.to_json
      else
        status 422
        {errors: 'Post could not be saved!'}.to_json
      end
    end
  end
end

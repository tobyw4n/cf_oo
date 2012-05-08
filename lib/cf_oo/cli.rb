require 'optparse'

module Cfoo
  module CLI
    def self.start
      action = ARGV[0]

      @options = Cfoo::CLI.parse_stack_command(:action => action)

      case action
      when 'create','describe', 'delete', 'instances', 'resources', 'template', 'update'
        app = @options[:app]
        name = @options[:name]
        environment = @options[:environment]

        # Optional params
        region = @options[:region] || 'us-west-1'

        # Create stack object
        @stack = Stack.new(:app => app,
                           :environment => environment,
                           :name => name,
                           :region => region)
      end

      case action
      when 'create'
        # Output what to do
        puts "Creating Stack: #{name} Environmenet: #{environment} Region: #{region}"

        # Setup stack object
        @stack = Stack.new(:app => app,
                           :environment => environment,
                           :name => name,
                           :region => region)

        # Read the requested template
        template_body = String.new
        File.open(@options[:template]) {|f| template_body<< f.read}
        @stack.template = template_body

        # Create stack
        @stack.create('Parameters' => @options[:parameters])

        # Wait for stack to come online
        until (@stack.online?) do
          puts @stack.events.first.to_yaml
          puts "Building. Sleeping for 60 seconds..."
          sleep 60
        end

        # Output completion
        puts "Stack: #{name} complete."
      when 'delete'
        puts "There is no going back."
        puts "Delete #{name} in #{environment}? (y/N): "
        confirm = STDIN.gets

        exit unless confirm.chomp.downcase == 'y'
        
        # Get stack output
        outputs = @stack.outputs
        
        # Empty s3 buckets
        puts "Emptying all S3 buckets."
        @stack.buckets.each do |bucket|
          @stack.empty_s3_bucket(bucket)
        end

        # Delete stack
        puts "Deleting stack."
        @stack.delete
      when 'update'
        # Read the requested template
        template_body = String.new

        # If a template is specified, use it, other wise update running template
        if @options[:template]
          File.open(@options[:template]) {|f| template_body<< f.read}
        else
          template_body = @stack.get_template
        end

        # Set the defaults within the template
        @stack.template = Cfoo::CLI.set_defaults(:template_body => template_body,
                                                :parameters => @options[:parameters]).to_json

        # Update the stack
        puts "Updating Stack: #{name} Environmenet: #{environment}"
        @stack.update('Parameters' => @options[:parameters])
      when 'describe'
        puts @stack.describe.to_yaml
      when 'instances'
        puts @stack.instances.to_yaml
      when 'list'
        puts Cfoo::Stack.list(:regions => ['us-west-1']).to_yaml
      when 'resources'
        puts @stack.resources.to_yaml
      when 'template'
        jj JSON.parse(@stack.get_template)
      else
        Cfoo::CLI.help(1)
      end
    end

    def self.parse_stack_command(args)
      options = {}

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} -n STACK_NAME -t TEMPLATE_FILE -r REGION"

        options[:app] = nil
        opts.on('-a', '--app APP', 'Required app attribute') do |app|
          options[:app] = app
        end

        options[:environment] = nil
        opts.on('-n', '--environment ENVIRONMENT', 'Required environment attribute') do |environment|
          options[:environment] = environment
        end

        options[:name] = nil
        opts.on('-n', '--name NAME', 'Required name attribute') do |name|
          options[:name] = name
        end

        options[:region] = nil
        opts.on('-r', '--region REGION', 'Required region attribute') do |region|
          options[:region] = region
        end

        options[:template] = nil
        opts.on('-t', '--template FILE', 'Set the template file for this stack') do |file|
          options[:template] = file
        end

        options[:parameters] = {}
        opts.on('-p', '--parameters KEY=VALUE', 'Set the parameters for a stack template',
          '(can be comma separated key value pairs)') do |params|
          params.split('?').each do |param|
            k,v = param.split('=')
            raise "Invalid parameter definition" unless v
            options[:parameters][k] = v
          end
        end
      end

      parser.parse!

      case args[:action]
      when 'describe', 'delete', 'instances', 'resources', 'template', 'update'
        required = [:app, :environment, :name]
      when 'create'  
        required = [:app, :environment, :name, :template, :parameters]
      else
        required = []
      end

      required.each do |p|
        raise "Missing required parameter: --#{p}" unless options[p]
      end

      options
    end 

    def self.help(code=0)
      puts "\ncf_oo [create|delete|describe|instances|list|resources|template|update] OPTIONS\n\n"
      puts "[create|update] options:"
      puts "-a app"
      puts "-e environment"
      puts "-n name"
      puts "-p parameters seperated by ? (ie. Param1=Value1)"
      puts "-r region"
      puts "-t template\n\n"
      puts "[delete|describe|instances|resources|template] options:"
      puts "-a app"
      puts "-e environment"
      puts "-n name"
      exit code
    end

  end
end

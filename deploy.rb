require 'aws-sdk'
require 'cmdparse'

opsworks = Aws::OpsWorks::Client.new(region: 'us-east-1')

parser = CmdParse::CommandParser.new(handle_exceptions: true)
parser.main_options.program_name = "deploy.rb"
parser.main_options.version = "0.1.0"
parser.main_options.banner = "Deploy to any Threads OpsWork environment. Must provide AWS credentials in environment variables or AWS credentials config."

parser.add_command(CmdParse::HelpCommand.new)

stacks = opsworks.describe_stacks.stacks



parser.add_command('status') do |command|
  command.short_desc "View current revision/branch of each OpsWorks stack"
  command.takes_commands(false)
  command.action do
    widths = [20,25,20]
    puts "#{'Stack'.ljust(widths[0])} #{'Domain'.ljust(widths[1])} #{'Branch/Tag'.ljust(widths[2])}"

    stacks.each do |stack|
      result = opsworks.describe_apps(stack_id: stack.stack_id)

      next if !result || result.apps.size < 1

      app = result.apps.first

      puts "#{stack.name.ljust(widths[0])} #{app.domains.join(',').ljust(widths[1])} #{app.app_source.revision.ljust(widths[2])}"
    end
    puts ""
  end
end


stacks.each do |stack|
  parser.add_command(stack.name) do |command|
    command.short_desc "Deploy to #{stack.name}"
    command.takes_commands(false)

    # Important: The order of these reflects the order they will be placed into the action opts array
    command.options.on('-l','--layer','web,worker')
    command.argument_desc(version: 'Branch/tag to deploy')

    command.action do |version, *opts|
      puts "Deploying #{version} to #{stack.name}"

      app = opsworks.describe_apps(stack_id: stack.stack_id).apps.first

      # See if any other deployments are still running first
      active_deploys = opsworks.describe_deployments(:stack_id => stack.stack_id).deployments.map do |deploy|
        deploy if !deploy.completed_at and deploy.command.name == 'deploy'
      end.compact

      if active_deploys.size > 0
        puts "Active deployment already in progress"
        puts "Please wait until this deployment is completed before starting another"
        puts ""
        next
      end

      # Modify App settings
      print "Changing from version #{app.app_source.revision} to #{version}..."
      opsworks.update_app(:app_id => app.app_id, :app_source => { :revision => version })
      print " done\n"
      $stdout.flush

      # Look up layers
      target_layers = opts.size > 0 ? opts[0].split(',') : ['web','worker']
      layers = opsworks.describe_layers(stack_id: stack.stack_id).layers.map do |layer|
        layer.layer_id if target_layers.include? layer.name.downcase
      end.compact

      print "Starting deploy..."
      # Create deployment
      deploy = opsworks.create_deployment(
          :stack_id => stack.stack_id,
          :app_id => app.app_id,
          :layer_ids => layers,
          :comment => "Deploying #{version} to #{target_layers.join(' and ')}",
          :command => { :name => "deploy" }
      )
      print "done (deployment ID: #{deploy.deployment_id})\n"
      $stdout.flush

      puts "Waiting for deploy to finish (this will take a few minutes).."
      puts ""
      puts "View log: https://console.aws.amazon.com/opsworks/home?region=us-east-1#/stack/#{stack.stack_id}/deployments/#{deploy.deployment_id}"
      puts ""

      started_at = Time.now.to_i
      loop do
        current_at = Time.now.to_i - started_at

        minutes = current_at / 60
        seconds = current_at % 60

        time = "#{minutes > 0 ? minutes.to_s + ' minutes, ' : ''}#{seconds} seconds"

        timer = "Time elapsed: #{time}"

        print timer
        $stdout.flush
        sleep 1
        print "\b"*timer.size

        break if current_at % 10 == 0 and opsworks.describe_deployments(:deployment_ids => [deploy.deployment_id]).deployments[0].completed_at
      end


      puts ""
      puts "Deployment finished in #{Time.now.to_i - started_at} seconds"
      puts "Status: #{opsworks.describe_deployments(:deployment_ids => [deploy.deployment_id]).deployments[0].status}"
    end
  end
end


parser.parse(ARGV)
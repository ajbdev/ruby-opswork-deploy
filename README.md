Deploy to any Threads OpsWork environment. Must provide AWS credentials in
environment variables or AWS credentials config.

```
Usage: deploy.rb {help | status | yourstack} {branch/tag} 

Available commands:
    help              Provide help for individual commands
    status            View current revision/branch of each OpsWorks stack
    yourstack         Deploy to the OpsWork stack named "yourstack"

Global Options:
    -h, --help                       Show help
    -l, --layer                      web,worker
```

The name of the stack you wish to deploy to is used as the first parameter of the script.

### Status

Status lists all stack with their current branch

```
ruby deploy.rb status

Stack                Domain                    Branch/Tag          
threads-qa           ourthreads-qa.com         vagrant-windows     
threads-staging      ourthreads-staging.com    532-feedback-visible-option
threads-production   ourthreads.com            1.50.4
```

### Deploying

To deploy:

```
$ ruby deploy.rb threads-qa 532-feedback-visible-option

Deploying 532-feedback-visible-option to threads-qa
Changing from version vagrant-windows to 532-feedback-visible-option... done
Targeted layers: web,worker
Starting deploy...done (deployment ID: cd219594-aa47-4615-8afa-f33ffb3c80ce)
Waiting for deploy to finish (this will take a few minutes)..

View log: https://console.aws.amazon.com/opsworks/home?region=us-east-1#/stack/adf8275e-5832-48e3-8516-7be156498d4c/deployments/cd219594-aa47-4615-8afa-f33ffb3c80ce

Note: exiting this process will not stop this deployment
```

Detaching from the process will not cancel the deployment.

You can target a specific layer by appending the --layer parameter:

```
$ ruby deploy.rb threads-staging 532-feedback-visible-option --layer worker

Changing from version 532-feedback-visible-option to 532-feedback-visible-option... done
Targeted layers: worker
...
```

Targeting a specific layer can be useful if, for example, a change contains migrations - you may want to first run it on your worker server before deploying to the remainder of your servers. 




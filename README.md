Deploy to any Threads OpsWork environment. Must provide AWS credentials in
environment variables or AWS credentials config.

```
Usage: deploy.rb {help | status | threads-production | threads-qa |
       threads-staging}

Available commands:
    help              Provide help for individual commands
    status            View current revision/branch of each OpsWorks stack
    threads-productionDeploy to threads-production
    threads-qa        Deploy to threads-qa
    threads-staging   Deploy to threads-staging

Global Options:
    -h, --help                       Show help
```


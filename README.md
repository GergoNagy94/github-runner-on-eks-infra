# eks-runner - Terragrunt Stack

- **Project**: eks-runner
- **Version**: 1.0.0
- **Created**: 2025-08-19
- **Created By**: nagygergo

## Environment Configuration

Environment: Development  
Region: eu-central-1  
Account ID: 567749996660

## Project Structure

```
.
├── infrastructure/
│   ├── root.hcl                                        # Common Terragrunt configuration
│   ├── project.hcl                                     # Project-specific variables
│   └── live/                                           # Environment-specific configurations
│       └── development/
│           └── eu-central-1
│               ├── region.hcl
│               └── terragrunt.stack.hcl
└── units/                                              # Reusable Terragrunt units
    ├── vpc/
    └── sg/
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- OpenTofu 1.10.2
- Terragrunt 0.82.3
- [mise](https://mise.jdx.dev/) for tool version management

## Getting Started
1. Install mise and required tools:

```bash
mise trust
mise install
```

2. Configure AWS credentials for each account:
```bash
aws configure --profile eks-runner-development
```

## Adding New Units
To add a new unit to the stack:

1. Add the unit configuration to `units/` directory
2. Regenerate the stack files or manually add the unit to `terragrunt.stack.hcl`

## Security Considerations
- All environments use IAM role assumption with `terragrunt-execution-role`
- State files are encrypted in S3
- DynamoDB tables are used for state locking
- Separate AWS accounts for each environment

## Troubleshooting
### Common Issues
2. **IAM role not found**: Ensure the `terragrunt-execution-role` exists in each account
3. **Region mismatch**: Verify the region settings in `region.hcl` files